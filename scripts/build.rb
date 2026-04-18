#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal static site builder
# Usage: ruby scripts/build.rb                (build)
#        ruby scripts/build.rb serve          (build + local server)
#        ruby scripts/build.rb serve --deploy (build without translations + local server)

require "fileutils"
require "yaml"
require "time"
require "json"
require "shellwords"
require "tempfile"
require "uri"
require "kramdown"
require "kramdown-parser-gfm"
require "rouge"

ROOT      = File.expand_path("..", __dir__)
CONTENT   = File.join(ROOT, "content")
TEMPLATES = File.join(ROOT, "templates")
STATIC    = File.join(ROOT, "static")
DOCS      = File.join(ROOT, "docs")
CACHE     = File.join(ROOT, ".cache", "images")
SITE_URL  = "https://yohasebe.com"

# Reference content width (px) used to calculate image display scaling.
CONTENT_WIDTH = 700

# Image extensions that should have EXIF / metadata stripped on copy
STRIP_IMAGE_EXTS = %w[.jpg .jpeg .png .gif .webp .tif .tiff].freeze

# --- Helpers ---

# Detect the ImageMagick command: "magick" (v7) or "convert"/"identify" (v6).
def magick_cmd
  return @magick_cmd if defined?(@magick_cmd)
  if system("magick", "-version", out: File::NULL, err: File::NULL)
    @magick_cmd = "magick"
  elsif system("convert", "-version", out: File::NULL, err: File::NULL)
    @magick_cmd = "convert"
  else
    @magick_cmd = nil
  end
end

def magick_available?
  !magick_cmd.nil?
end

# Copy a single file, stripping EXIF/metadata for images.
# Uses a persistent content cache (by source path + mtime) so the expensive
# ImageMagick call only runs when the source has actually changed.
def copy_asset(src, dest)
  FileUtils.mkdir_p(File.dirname(dest))
  ext = File.extname(src).downcase

  unless STRIP_IMAGE_EXTS.include?(ext) && magick_available?
    FileUtils.cp(src, dest)
    return
  end

  # Cache path mirrors the source path relative to ROOT.
  rel = src.sub(/\A#{Regexp.escape(ROOT)}\/?/, "")
  cache_path = File.join(CACHE, rel)

  if !File.exist?(cache_path) || File.mtime(cache_path) < File.mtime(src)
    FileUtils.mkdir_p(File.dirname(cache_path))
    # -auto-orient bakes EXIF Orientation into pixels before stripping.
    # -colorspace sRGB ensures color consistency after ICC profile removal.
    cmd = magick_cmd == "magick" ? ["magick", src] : ["convert", src]
    ok = system(*cmd, "-auto-orient", "-colorspace", "sRGB", "-strip", cache_path)
    unless ok
      warn "WARNING: magick failed for #{src}; copying as-is"
      FileUtils.cp(src, dest)
      return
    end
  end

  FileUtils.cp(cache_path, dest)
end

# Recursively copy a directory tree, running copy_asset on each file.
def copy_tree(src_dir, dest_dir)
  Dir.glob(File.join(src_dir, "**", "*"), File::FNM_DOTMATCH).each do |path|
    base = File.basename(path)
    next if base == "." || base == ".."
    rel = path.sub(/\A#{Regexp.escape(src_dir)}\/?/, "")
    target = File.join(dest_dir, rel)
    if File.directory?(path)
      FileUtils.mkdir_p(target)
    else
      copy_asset(path, target)
    end
  end
end

# Return [width, height] in pixels for an image file, or nil on failure.
def image_dimensions(path)
  return nil unless File.exist?(path)
  ext = File.extname(path).downcase
  if ext == ".svg"
    svg = File.read(path, encoding: "UTF-8")
    # Try width/height attributes first (more reliable than viewBox parsing)
    w = svg[/\bwidth="([\d.]+)"/, 1]
    h = svg[/\bheight="([\d.]+)"/, 1]
    return [w.to_f, h.to_f] if w && h
    # Fallback: parse viewBox="minX minY width height"
    if svg =~ /viewBox="[\d.]+[\s,]+[\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)"/
      return [$1.to_f, $2.to_f]
    end
  else
    # Use identify for raster images (first frame only for animated GIFs)
    identify = magick_cmd == "magick" ? "magick identify" : "identify"
    out = `#{identify} -format "%w %h\\n" #{path.shellescape}[0] 2>/dev/null`.strip
    parts = out.split
    return [parts[0].to_f, parts[1].to_f] if parts.size == 2
  end
  nil
end

# Inject inline max-width on <img> tags based on the image's intrinsic width
# relative to CONTENT_WIDTH. source_dir is the directory to resolve relative src.
def auto_size_images(html, source_dir)
  html.gsub(/<img\s([^>]*)src="([^"]+)"([^>]*)>/) do
    match = $~[0]
    pre, src, post = $1, $2, $3
    has_loading = (pre + post).include?("loading=")
    # Skip resize if already has inline style with max-width
    if (pre + post).include?("max-width")
      has_loading ? match : match.sub("<img ", '<img loading="lazy" ')
    else
      img_path = File.expand_path(src, source_dir)
      dims = image_dimensions(img_path)
      if dims
        w = dims[0]
        # Map intrinsic width to a display percentage of CONTENT_WIDTH.
        # Wide images fill more of the column; narrow ones shrink.
        ratio = (w / CONTENT_WIDTH.to_f).clamp(0.0, 3.0)
        pct = case ratio
              when 0.0..0.4  then 45
              when 0.4..0.7  then 55
              when 0.7..1.0  then 70
              when 1.0..1.5  then 80
              when 1.5..2.0  then 90
              else                100
              end
        # Remove trailing " /" from self-closing tags before injecting style
        clean_post = post.sub(/\s*\/\s*\z/, "")
        loading_attr = has_loading ? "" : %( loading="lazy")
        %(<img#{loading_attr} #{pre}src="#{src}"#{clean_post} style="max-width:#{pct}%" />)
      else
        has_loading ? match : match.sub("<img ", '<img loading="lazy" ')
      end
    end
  end
end

def read_template(name)
  path = File.join(TEMPLATES, "#{name}.html")
  abort "ERROR: Template not found: #{path}" unless File.exist?(path)
  File.read(path)
end

def parse_frontmatter(path)
  raw = File.read(path)
  if raw =~ /\A---\s*\n(.*?\n)---\s*\n(.*)\z/m
    begin
      meta = YAML.safe_load($1, permitted_classes: [Date, Time])
    rescue Psych::SyntaxError => e
      warn "WARNING: YAML parse error in #{path}: #{e.message}"
      meta = {}
    end
    body = $2
  else
    meta = {}
    body = raw
  end
  [meta, body]
end

def render_markdown(text)
  # Protect math expressions from Markdown processing
  placeholders = {}
  counter = 0

  # Block math: $$...$$
  protected = text.gsub(/\$\$(.+?)\$\$/m) do
    key = "KATEXBLOCK#{counter}XETAK"
    placeholders[key] = "<div class=\"math-block\">$$#{$1}$$</div>"
    counter += 1
    key
  end

  # Inline math: $...$ (content must start with non-digit, non-space to avoid matching prices like $10)
  protected = protected.gsub(/(?<!\$)\$(?!\$|\d| )(.+?)(?<!\$| )\$(?!\$)/) do
    key = "KATEXINLINE#{counter}XETAK"
    placeholders[key] = "<span class=\"math-inline\">$#{$1}$</span>"
    counter += 1
    key
  end

  html = Kramdown::Document.new(protected, input: "GFM", syntax_highlighter: "rouge", smart_quotes: ["apos", "apos", "quot", "quot"]).to_html

  # Restore math expressions
  placeholders.each { |key, val| html.gsub!(key, val) }
  html
end

def apply_template(template_str, vars)
  result = template_str.dup

  # Conditional sections: {{#key}}...{{/key}}
  result.gsub!(/\{\{#(\w+)\}\}(.*?)\{\{\/\1\}\}/m) do
    key = $1; inner = $2
    vars[key] && !vars[key].to_s.empty? ? inner : ""
  end

  # Variable substitution
  vars.each do |k, v|
    result.gsub!("{{#{k}}}", v.to_s)
  end

  result
end

def escape_html(s)
  s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

def wrap_in_base(content, title:, lang: "en", root: "./", body_class: "", og_type: "website", og_url: SITE_URL, og_description: "", ld_json: nil)
  base = read_template("base")
  desc = og_description.empty? ? "Blog by Yoichiro Hasebe" : og_description
  apply_template(base, {
    "content"        => content,
    "title"          => escape_html(title),
    "lang"           => lang,
    "root"           => root,
    "body_class"     => body_class,
    "og_type"        => og_type,
    "og_url"         => og_url,
    "og_description" => escape_html(desc),
    "ld_json"        => ld_json || "",
  })
end

def relative_root(output_path)
  depth = output_path.sub(DOCS + "/", "").count("/")
  depth == 0 ? "./" : ("../" * depth)
end

def date_iso(meta)
  d = meta["date"]
  case d
  when Time then d.strftime("%Y-%m-%d")
  when Date then d.strftime("%Y-%m-%d")
  when String then d
  else Time.now.strftime("%Y-%m-%d")
  end
end

def date_display(meta)
  d = meta["date"]
  t = case d
      when Time then d
      when Date then d.to_time
      when String then Time.parse(d)
      else Time.now
      end
  t.strftime("%b %d, %Y")
end

def updated_iso(meta)
  d = meta["updated"]
  return nil unless d
  date_iso("date" => d)
end

def updated_display(meta)
  d = meta["updated"]
  return nil unless d
  date_display("date" => d)
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
  puts "  #{path.sub(ROOT + '/', '')}"
end

# --- Collect posts/notes ---

def collect_entries(subdir)
  dir = File.join(CONTENT, subdir)
  return [] unless Dir.exist?(dir)

  entries = []
  Dir.glob(File.join(dir, "**/index.md")).each do |path|
    meta, body = parse_frontmatter(path)
    next if meta["draft"]

    slug = File.dirname(path).sub(dir + "/", "")
    entries << {
      meta: meta,
      body: body,
      slug: slug,
      source_dir: File.dirname(path),
      section: subdir,
    }
  end

  entries.sort_by { |e| e[:meta]["date"].to_s }.reverse
end

# --- Build ---

DEPLOY_MODE = ARGV.include?("--deploy")

TRANSLATIONS = {
  "ja" => { label: "日本語", notice: "この記事はAIによって英語から翻訳されました。" },
  "zh" => { label: "中文",   notice: "本文由AI从英语翻译而来。" },
  "ko" => { label: "한국어", notice: "이 글은 AI에 의해 영어에서 번역되었습니다." },
}

def detect_translations(source_dir)
  return {} if DEPLOY_MODE
  available = {}
  TRANSLATIONS.each do |code, _|
    path = File.join(source_dir, "#{code}.md")
    if File.exist?(path)
      meta, body = parse_frontmatter(path)
      available[code] = { meta: meta, body: body }
    end
  end
  available
end

# Warn if translated posts are missing images present in the English version.
def warn_image_mismatch(entry, translations)
  en_images = entry[:body].scan(/!\[[^\]]*\]\(([^)]+)\)/).flatten.sort
  return if en_images.empty?

  translations.each do |code, trans|
    trans_images = trans[:body].scan(/!\[[^\]]*\]\(([^)]+)\)/).flatten.sort
    missing = en_images - trans_images
    extra   = trans_images - en_images
    slug = entry[:slug]
    missing.each { |img| warn "WARNING: #{slug}/#{code}.md is missing image: #{img}" }
    extra.each   { |img| warn "WARNING: #{slug}/#{code}.md has extra image not in index.md: #{img}" }
  end
end

def build_lang_nav(base_url, available_langs, current_lang)
  links = []
  links << if current_lang == "en"
             %(<span class="lang-current">English</span>)
           else
             %(<a href="#{base_url}">English</a>)
           end

  TRANSLATIONS.each do |code, info|
    next unless available_langs.include?(code)
    links << if current_lang == code
               %(<span class="lang-current">#{info[:label]}</span>)
             else
               %(<a href="#{base_url}#{code}/">#{info[:label]}</a>)
             end
  end

  links.join
end

def entry_path(entry)
  "#{entry[:section]}/#{entry[:slug]}/"
end

def translated_title(entry, lang_code)
  return entry[:meta]["title"] || entry[:slug] if lang_code.nil?
  trans_path = File.join(entry[:source_dir], "#{lang_code}.md")
  if File.exist?(trans_path)
    meta, _ = parse_frontmatter(trans_path)
    meta["title"] || entry[:meta]["title"] || entry[:slug]
  else
    entry[:meta]["title"] || entry[:slug]
  end
end

def build_post_nav(prev_entry, next_entry, root, lang_suffix = "", lang_code: nil)
  parts = []
  if prev_entry
    title = translated_title(prev_entry, lang_code)
    href = "#{root}#{entry_path(prev_entry)}#{lang_suffix}"
    parts << %(<span class="post-nav-prev">&larr; <a href="#{href}">#{title}</a></span>)
  end
  if next_entry
    title = translated_title(next_entry, lang_code)
    href = "#{root}#{entry_path(next_entry)}#{lang_suffix}"
    parts << %(<span class="post-nav-next"><a href="#{href}">#{title}</a> &rarr;</span>)
  end
  parts.join
end

# Convert ```mermaid code blocks to SVG image files.
# Returns the markdown with mermaid blocks replaced by ![](*.svg) references.
# If a pre-generated SVG exists in source_dir, use it without running mmdc.
def convert_mermaid(markdown, out_dir, source_dir: nil)
  has_mmdc = system("which mmdc > /dev/null 2>&1")
  counter = 0
  markdown.gsub(/```mermaid\s*\n(.*?)```/m) do
    mermaid_src = $1
    counter += 1
    svg_name = "mermaid-#{counter}.svg"
    svg_path = File.join(out_dir, svg_name)

    # Check if pre-generated SVG exists in source directory
    if source_dir && File.exist?(File.join(source_dir, svg_name))
      "![](#{svg_name})"
    elsif has_mmdc
      FileUtils.mkdir_p(out_dir)
      Tempfile.create(["mermaid", ".mmd"]) do |tmp|
        tmp.write(mermaid_src)
        tmp.flush
        system("mmdc", "-i", tmp.path, "-o", svg_path, "-b", "transparent",
               out: File::NULL, err: File::NULL)
      end
      File.exist?(svg_path) ? "![](#{svg_name})" : "```mermaid\n#{mermaid_src}```"
    else
      "```mermaid\n#{mermaid_src}```"
    end
  end
end

def build_entry(entry, prev_entry: nil, next_entry: nil)
  section = entry[:section]
  slug    = entry[:slug]
  meta    = entry[:meta]
  out_dir = File.join(DOCS, section, slug)
  body = convert_mermaid(entry[:body], out_dir, source_dir: entry[:source_dir])
  html    = render_markdown(body)

  out_dir = File.join(DOCS, section, slug)
  out_path = File.join(out_dir, "index.html")

  # Copy all non-Markdown assets from the post directory (images, audio, etc.)
  Dir.children(entry[:source_dir]).each do |child|
    src = File.join(entry[:source_dir], child)
    next if child.end_with?(".md")
    dest = File.join(out_dir, child)
    if File.directory?(src)
      FileUtils.mkdir_p(dest)
      copy_tree(src, dest)
    else
      copy_asset(src, dest)
    end
  end

  # Auto-size images based on intrinsic dimensions (resolve relative to source dir)
  html = auto_size_images(html, entry[:source_dir])

  # Detect available translations
  translations = detect_translations(entry[:source_dir])
  warn_image_mismatch(entry, translations)
  base_url = "./";
  lang_nav = translations.empty? ? "" : build_lang_nav(base_url, translations.keys, "en")

  root = relative_root(out_path)
  # Fix relative asset paths for post subdirectory
  html.gsub!(/href="assets\//, "href=\"#{root}assets/")

  tags_html = (meta["tags"] || []).map { |t|
    %(<a href="#{root}tags/#{slug_for_tag(t)}/">#{t}</a>)
  }.join(" ")

  discuss_title = "Re: #{meta["title"] || slug}"
  discuss_body = "> [#{meta["title"] || slug}](#{SITE_URL}/#{section}/#{slug}/)\n\n"
  discuss_url = "https://github.com/yohasebe/yohasebe.github.io/discussions/new?category=posts&title=#{URI.encode_www_form_component(discuss_title)}&body=#{URI.encode_www_form_component(discuss_body)}"

  post_html = apply_template(read_template("post"), {
    "title"        => meta["title"] || slug,
    "date_iso"     => date_iso(meta),
    "date_display" => date_display(meta),
    "updated_iso"  => updated_iso(meta) || "",
    "updated_display" => updated_display(meta) || "",
    "tags"         => meta["tags"] ? "1" : "",
    "tags_html"    => tags_html,
    "lang_nav"     => lang_nav,
    "ai_notice"    => "",
    "content"      => html,
    "discuss_url"  => discuss_url,
    "post_nav"     => build_post_nav(prev_entry, next_entry, root),
  })

  lang = meta["lang"] || "en"
  post_title = meta["title"] || slug
  post_url = "#{SITE_URL}/#{section}/#{slug}/"
  post_desc = meta["description"] || body
    .gsub(/```mermaid\s*\n.*?```/m, "")    # strip mermaid blocks
    .gsub(/!\[[^\]]*\]\([^)]*\)/, "")      # strip image references
    .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')   # [text](url) -> text
    .gsub(/<[^>]+>/, "")                   # strip HTML tags
    .gsub(/\{::nomarkdown\}.*?\{:\/nomarkdown\}/m, "") # strip nomarkdown
    .gsub(/[#*>]/, "")                     # strip markdown formatting
    .gsub(/\s+/, " ").strip[0, 200]
    .sub(/\s+\S*\z/, "")
  ld_data = {
    "@context" => "https://schema.org",
    "@type" => "BlogPosting",
    "headline" => post_title,
    "description" => post_desc,
    "datePublished" => date_iso(meta),
    "url" => post_url,
    "author" => {
      "@type" => "Person",
      "name" => "Yoichiro Hasebe",
      "url" => SITE_URL,
    },
    "mainEntityOfPage" => { "@type" => "WebPage", "@id" => post_url },
  }
  ld_data["dateModified"] = updated_iso(meta) if updated_iso(meta)
  ld_json = %(<script type="application/ld+json">#{JSON.generate(ld_data)}</script>)

  page = wrap_in_base(post_html, title: post_title, lang: lang, root: root,
                       og_type: "article", og_url: post_url, og_description: post_desc,
                       ld_json: ld_json)
  write_file(out_path, page)

  # Build translated versions
  translations.each do |code, trans|
    trans_body = convert_mermaid(trans[:body], out_dir, source_dir: entry[:source_dir])
    trans_html = render_markdown(trans_body)
    # Auto-size images before path rewriting (src still relative to source_dir)
    trans_html = auto_size_images(trans_html, entry[:source_dir])
    trans_title = trans[:meta]["title"] || meta["title"] || slug
    trans_out_path = File.join(out_dir, code, "index.html")
    trans_root = relative_root(trans_out_path)
    # Fix relative paths for subdirectory (e.g., ja/index.html -> ../images/, ../../assets/)
    trans_html.gsub!(/src="images\//, 'src="../images/')
    trans_html.gsub!(/href="assets\//, "href=\"#{trans_root}assets/")
    # Fix relative src/href for non-directory files (e.g., mp3, png at post root)
    trans_html.gsub!(/src="([^"\/][^"]*\.(mp3|ogg|wav|png|jpg|jpeg|gif|webp|svg))"/) { %{src="../#{$1}"} }
    trans_html.gsub!(/href="(\.\.\/\d{4}-[^"]*)"/) { %{href="../../#{$1.sub('../', '')}"} }
    trans_lang_nav = build_lang_nav("../", translations.keys, code)

    trans_tags_html = (meta["tags"] || []).map { |t|
      %(<a href="#{trans_root}tags/#{slug_for_tag(t)}/">#{t}</a>)
    }.join(" ")

    trans_post_html = apply_template(read_template("post"), {
      "title"        => trans_title,
      "date_iso"     => date_iso(meta),
      "date_display" => date_display(meta),
      "updated_iso"  => updated_iso(meta) || "",
      "updated_display" => updated_display(meta) || "",
      "tags"         => meta["tags"] ? "1" : "",
      "tags_html"    => trans_tags_html,
      "lang_nav"     => trans_lang_nav,
      "ai_notice"    => TRANSLATIONS[code][:notice],
      "content"      => trans_html,
      "discuss_url"  => discuss_url,
      "post_nav"     => build_post_nav(prev_entry, next_entry, trans_root, "#{code}/", lang_code: code),
    })

    page = wrap_in_base(trans_post_html, title: trans_title, lang: code, root: trans_root)
    write_file(trans_out_path, page)
  end

  { path: "#{section}/#{slug}/", meta: meta, body: entry[:body] }
end

def slug_for_tag(tag)
  tag.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
end

PROJECTS = [
  { name: "Monadic Chat", desc: "Grounding AI chatbots with full Linux environment on Docker", url: "https://yohasebe.github.io/monadic-chat", logo: "assets/images/projects/monadic-chat-logo.png", logo_h: 72 },
  { name: "TCSE", desc: "TED Corpus Search Engine for education and research", url: "https://yohasebe.com/tcse", logo: "assets/images/projects/tcse-logo.png", logo_h: 56 },
  { name: "RSyntaxTree", desc: "Syntax tree generator for linguistics", url: "https://yohasebe.com/rsyntaxtree", logo: "assets/images/projects/rsyntaxtree-icon.png", logo_h: 56 },
  { name: "jReadability", desc: "Japanese text readability measurement system", url: "https://jreadability.net", logo: "assets/images/projects/jreadability-logo.png", logo_h: 48 },
  { name: "jWriter", desc: "Japanese learner writing evaluation system", url: "https://jreadability.net/jwriter", logo: "assets/images/projects/jwriter-logo.png", logo_h: 44 },
  { name: "Paradocs", desc: "Paragraph-oriented text presentation system", url: "https://yohasebe.github.io/paradocs", logo: "assets/images/projects/paradocs-icon.png", logo_h: 56 },
  { name: "SpeechDock", desc: "Speech-to-text transcription tool", url: "https://github.com/yohasebe/speechdock", logo: "assets/images/projects/speechdock-icon.png", logo_h: 56 },
  { name: "wp2txt", desc: "Wikipedia dump to plain text converter", url: "https://github.com/yohasebe/wp2txt", logo: "assets/images/projects/wp2txt-logo.svg", logo_h: 56 },
]

def build_projects_html(root)
  items = PROJECTS.map { |p|
    <<~ITEM
      <li>
        <a href="#{p[:url]}" class="project-item">
          <img src="#{root}#{p[:logo]}" alt="#{p[:name]}" style="height:#{p[:logo_h]}px">
          <span class="project-text"><span class="project-name">#{p[:name]}</span>: #{p[:desc]}</span>
        </a>
      </li>
    ITEM
  }.join

  <<~HTML
    <section class="projects">
      <h2>Projects</h2>
      <ul class="project-list">
        #{items}
      </ul>
      <p class="projects-more"><a href="https://github.com/yohasebe">More on GitHub →</a></p>
    </section>
  HTML
end

def build_index(entries, heading:, out_path:)
  root = relative_root(out_path)

  items = entries.map { |e|
    tags = (e[:meta]["tags"] || []).map { |t|
      %(<a href="#{root}tags/#{slug_for_tag(t)}/" class="index-tag">#{t}</a>)
    }.join
    tags_span = tags.empty? ? "" : %(<span class="index-tags">#{tags}</span>)
    %(<li class="h-entry"><time class="dt-published" datetime="#{date_iso(e[:meta])}">#{date_display(e[:meta])}</time><a class="u-url p-name" href="#{root}#{e[:path]}">#{e[:meta]["title"] || e[:slug]}</a>#{tags_span}</li>)
  }.join("\n  ")

  index_html = apply_template(read_template("index"), {
    "heading" => heading,
    "entries" => items,
  })

  page = wrap_in_base(index_html, title: heading, root: root)
  write_file(out_path, page)
end

def build_tag_pages(all_entries)
  tags = {}
  all_entries.each do |e|
    (e[:meta]["tags"] || []).each do |t|
      (tags[t] ||= []) << e
    end
  end

  # Tag index page
  root_path = File.join(DOCS, "tags", "index.html")
  root = relative_root(root_path)
  cloud = tags.sort_by { |t, _| t.downcase }.map { |t, es|
    %(<a href="#{root}tags/#{slug_for_tag(t)}/">#{t} (#{es.size})</a>)
  }.join("\n  ")

  cloud_html = "<h1>Tags</h1>\n<ul class=\"tag-cloud\">\n  #{cloud}\n</ul>"
  page = wrap_in_base(cloud_html, title: "Tags", root: root)
  write_file(root_path, page)

  # Individual tag pages
  tags.each do |tag, entries|
    out_path = File.join(DOCS, "tags", slug_for_tag(tag), "index.html")
    root = relative_root(out_path)

    items = entries.map { |e|
      tags = (e[:meta]["tags"] || []).map { |t|
        %(<a href="#{root}tags/#{slug_for_tag(t)}/" class="index-tag">#{t}</a>)
      }.join
      tags_span = tags.empty? ? "" : %(<span class="index-tags">#{tags}</span>)
      %(<li><time datetime="#{date_iso(e[:meta])}">#{date_display(e[:meta])}</time><a href="#{root}#{e[:path]}">#{e[:meta]["title"] || e[:slug]}</a>#{tags_span}</li>)
    }.join("\n  ")

    tag_html = apply_template(read_template("tag"), {
      "tag"     => tag,
      "entries" => items,
      "root"    => root,
    })

    page = wrap_in_base(tag_html, title: "Tag: #{tag}", root: root)
    write_file(out_path, page)
  end
end

def build_rss(entries)
  items = entries.first(20).map { |e|
    html = render_markdown(e[:body]) rescue ""
    summary = (e[:meta]["description"] || e[:body]
      .gsub(/```.*?```/m, "")
      .gsub(/!\[[^\]]*\]\([^)]*\)/, "")
      .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
      .gsub(/<[^>]+>/, "")
      .gsub(/[#*>]/, "")
      .gsub(/\s+/, " ").strip)[0, 140].sub(/\s+\S*\z/, "")
    <<~ITEM
      <item>
        <title>#{escape_xml(e[:meta]["title"] || e[:slug])}</title>
        <link>#{SITE_URL}/#{e[:path]}</link>
        <guid isPermaLink="true">#{SITE_URL}/#{e[:path]}</guid>
        <pubDate>#{Time.parse(date_iso(e[:meta])).rfc2822}</pubDate>
        <description>#{escape_xml(summary)}</description>
        <content:encoded><![CDATA[#{html}]]></content:encoded>
      </item>
    ITEM
  }.join

  rss = <<~RSS
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title>Yoichiro Hasebe</title>
      <link>#{SITE_URL}/</link>
      <atom:link href="#{SITE_URL}/feed.xml" rel="self" type="application/rss+xml" />
      <description>Posts by Yoichiro Hasebe</description>
      #{items}
    </channel>
    </rss>
  RSS

  write_file(File.join(DOCS, "feed.xml"), rss)
end

def build_sitemap(entries)
  urls = []
  urls << %{  <url><loc>#{SITE_URL}/</loc></url>}
  urls << %{  <url><loc>#{SITE_URL}/tags/</loc></url>}
  urls << %{  <url><loc>#{SITE_URL}/cv/</loc></url>}
  urls << %{  <url><loc>#{SITE_URL}/projects/</loc></url>}
  urls << %{  <url><loc>#{SITE_URL}/search/</loc></url>}
  entries.each do |e|
    urls << %{  <url><loc>#{SITE_URL}/#{e[:path]}</loc><lastmod>#{date_iso(e[:meta])}</lastmod></url>}
  end
  sitemap = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{urls.join("\n")}
    </urlset>
  XML
  write_file(File.join(DOCS, "sitemap.xml"), sitemap)
end

def escape_xml(s)
  s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

def strip_html(html)
  html.gsub(/<[^>]+>/, "").gsub(/\s+/, " ").strip
end

def tokenize(text)
  text.downcase.scan(/[a-z0-9\u3040-\u9fff\uf900-\ufaff]+/)
end

def build_search_index(entries)
  # docs: array of {title, path, date, tags} for display
  docs = []
  # inverted index: word => [doc_id, ...]
  inverted = {}

  entries.each_with_index do |e, id|
    docs << {
      t: e[:meta]["title"] || "",
      p: e[:path],
      d: date_display(e[:meta]),
      tg: e[:meta]["tags"] || [],
    }

    plain = strip_html(render_markdown(e[:body]))
    title = e[:meta]["title"] || ""
    tags = (e[:meta]["tags"] || []).join(" ")
    words = tokenize("#{title} #{tags} #{plain}").uniq

    words.each do |w|
      (inverted[w] ||= []) << id
    end
  end

  data = { docs: docs, idx: inverted }
  write_file(File.join(DOCS, "search-index.json"), JSON.generate(data))
end

def build_search_page
  out_path = File.join(DOCS, "search", "index.html")
  root = relative_root(out_path)

  search_html = <<~HTML
    <h1>Search</h1>
    <input type="text" id="search-input" placeholder="Search posts..." autofocus>
    <p class="search-hint">English only. Prefix matching (e.g. "ling" matches "linguistics").</p>
    <ul id="search-results" class="post-list"></ul>
    <script>
      let docs = [], idx = {};
      fetch('#{root}search-index.json')
        .then(r => r.json())
        .then(data => { docs = data.docs; idx = data.idx; });

      const input = document.getElementById('search-input');
      const results = document.getElementById('search-results');

      function search(query) {
        const words = query.toLowerCase().match(/[a-z0-9\\u3040-\\u9fff\\uf900-\\ufaff]+/g);
        if (!words || words.length === 0) return [];
        // For each word, find all doc IDs that contain a key starting with that prefix
        const sets = words.map(w => {
          const ids = new Set();
          for (const key in idx) {
            if (key.startsWith(w)) idx[key].forEach(id => ids.add(id));
          }
          return ids;
        });
        // Intersect all sets
        let result = sets[0];
        for (let i = 1; i < sets.length; i++) {
          result = new Set([...result].filter(id => sets[i].has(id)));
        }
        return [...result];
      }

      input.addEventListener('input', () => {
        const q = input.value.trim();
        results.innerHTML = '';
        if (q.length < 2) return;
        const ids = search(q);
        ids.forEach(id => {
          const e = docs[id];
          const tagsHtml = (e.tg || []).map(t => {
            const slug = t.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
            return '<a href="#{root}tags/' + slug + '/" class="index-tag">' + t + '</a>';
          }).join('');
          const tagsSpan = tagsHtml ? '<span class="index-tags">' + tagsHtml + '</span>' : '';
          const li = document.createElement('li');
          li.innerHTML = '<time>' + e.d + '</time><a href="#{root}' + e.p + '">' + e.t + '</a>' + tagsSpan;
          results.appendChild(li);
        });
        if (ids.length === 0) {
          results.innerHTML = '<li>No results found.</li>';
        }
      });
    </script>
  HTML

  page = wrap_in_base(search_html, title: "Search", root: root)
  write_file(out_path, page)
end

def generate_toc(html)
  headings = html.scan(/<h2[^>]*id="([^"]*)"[^>]*>(.*?)<\/h2>/i)
  return "" if headings.size < 2

  items = headings.map { |id, text|
    clean = text.gsub(/<[^>]+>/, "").strip
    %(<li><a href="##{id}">#{clean}</a></li>)
  }.join("\n    ")

  <<~TOC
    <nav class="toc">
      <details open>
        <summary>Contents</summary>
        <ol>
          #{items}
        </ol>
      </details>
    </nav>
  TOC
end

def build_static_pages
  # Projects page
  out_path = File.join(DOCS, "projects", "index.html")
  root = relative_root(out_path)
  projects_html = build_projects_html(root)
  page = wrap_in_base("<article>\n#{projects_html}\n</article>",
                       title: "Projects", root: root)
  write_file(out_path, page)

  # CV page (if exists)
  cv_path = File.join(CONTENT, "cv.md")
  if File.exist?(cv_path)
    meta, body = parse_frontmatter(cv_path)
    html = render_markdown(body)
    out_path = File.join(DOCS, "cv", "index.html")
    root = relative_root(out_path)
    # Fix relative asset paths for subdirectory pages
    html.gsub!(/href="assets\//, "href=\"#{root}assets/")
    toc = generate_toc(html)
    page = wrap_in_base("<article>\n<h1>#{meta["title"] || "CV"}</h1>\n#{toc}#{html}\n</article>",
                         title: meta["title"] || "CV", root: root)
    write_file(out_path, page)
  end
end

def build!
  puts "Building site..."
  FileUtils.rm_rf(DOCS)
  FileUtils.mkdir_p(DOCS)

  # Copy static files
  FileUtils.cp_r(Dir.glob(File.join(STATIC, "*")), DOCS)

  # Copy document assets (PDFs etc.; images are EXIF-stripped)
  assets_src = File.join(ROOT, "assets")
  if Dir.exist?(assets_src)
    copy_tree(assets_src, File.join(DOCS, "assets"))
  end

  # Build posts (with prev/next navigation)
  posts = collect_entries("posts")
  built_posts = posts.each_with_index.map { |e, i|
    older  = i < posts.size - 1 ? posts[i + 1] : nil
    newer  = i > 0 ? posts[i - 1] : nil
    build_entry(e, prev_entry: older, next_entry: newer)
  }

  # Index page
  build_index(built_posts, heading: "Posts", out_path: File.join(DOCS, "index.html"))

  # Tags
  build_tag_pages(built_posts)

  # Static pages (CV etc.)
  build_static_pages

  # RSS
  build_rss(built_posts)

  # Search
  build_search_index(built_posts)
  build_search_page

  # 404 page
  not_found_html = <<~HTML
    <article>
      <h1>Page not found</h1>
      <p>The page you're looking for doesn't exist. <a href="/">Back to Posts</a></p>
    </article>
  HTML
  page_404 = wrap_in_base(not_found_html, title: "Not Found", root: "/")
  write_file(File.join(DOCS, "404.html"), page_404)

  # Sitemap
  build_sitemap(built_posts)

  # robots.txt
  robots_txt = <<~TXT
    User-agent: *
    Allow: /
    Sitemap: #{SITE_URL}/sitemap.xml
  TXT
  write_file(File.join(DOCS, "robots.txt"), robots_txt)

  # Root-level icons that browsers and clients fetch by convention
  # (e.g. /favicon.ico, /apple-touch-icon.png).
  favicon_ico_src = File.join(ROOT, "assets", "images", "favicon.ico")
  favicon_png_src = File.join(ROOT, "assets", "images", "favicon.png")
  if File.exist?(favicon_ico_src)
    FileUtils.cp(favicon_ico_src, File.join(DOCS, "favicon.ico"))
  end
  if File.exist?(favicon_png_src)
    FileUtils.cp(favicon_png_src, File.join(DOCS, "apple-touch-icon.png"))
    FileUtils.cp(favicon_png_src, File.join(DOCS, "apple-touch-icon-precomposed.png"))
  end

  puts "Done! #{built_posts.size} entries built."
end

# --- Main ---

build!

if ARGV.include?("serve")
  require "webrick"
  mime_types = WEBrick::HTTPUtils::DefaultMimeTypes.merge("mp3" => "audio/mpeg", "ogg" => "audio/ogg", "wav" => "audio/wav")
  server = WEBrick::HTTPServer.new(Port: 4000, DocumentRoot: DOCS, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [], MimeTypes: mime_types)

  # Auto-rebuild on file changes using fswatch
  watch_dirs = [CONTENT, TEMPLATES, STATIC].select { |d| Dir.exist?(d) }.join(" ")
  fswatch_available = system("which fswatch > /dev/null 2>&1")

  if fswatch_available && !watch_dirs.empty?
    watcher = Thread.new do
      IO.popen("fswatch -r -l 1 #{watch_dirs}") do |io|
        io.each_line do
          puts "\n[#{Time.now.strftime('%H:%M:%S')}] Change detected, rebuilding..."
          build!
        end
      end
    end
    puts "\nServing at http://localhost:4000/ (auto-rebuild enabled, Ctrl+C to stop)"
  else
    puts "\nServing at http://localhost:4000/ (Ctrl+C to stop)"
  end

  trap("INT") { server.shutdown }
  server.start
end
