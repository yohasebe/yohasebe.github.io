# yohasebe.com

Source repository for [yohasebe.com](https://yohasebe.com) -- a personal blog about linguistics, software, music, and other interests.

## How it works

```mermaid
%%{ init: { "flowchart": { "curve": "linear" } } }%%
flowchart LR
    subgraph Local
        write["Write Markdown"] -- build.rb --> preview["Preview"]
        preview -. fswatch .-> write
    end

    subgraph GitHub
        repo[("Repository")]
    end

    subgraph Server["yohasebe.com"]
        pull["git pull"] --> build["build.rb"] --> nginx["nginx"]
    end

    write -- "git push" --> repo
    repo -- "webhook" --> pull
```

## Tech stack

- **Generator**: Custom Ruby script ([`scripts/build.rb`](scripts/build.rb))
- **Markdown**: kramdown + GFM + Rouge (syntax highlighting) + KaTeX (math)
- **Search**: Client-side full-text search (inverted index built at build time)
- **Deploy**: Automated via GitHub webhook

## License

Text content is licensed under [CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0/).
