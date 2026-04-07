---
title: "ruby-spacy: Connecting spaCy and LLMs in Ruby"
date: 2026-02-23
tags: [software, nlp, ai]
---

I released version 0.4.0 of [ruby-spacy](https://github.com/yohasebe/ruby-spacy), a wrapper that lets you use Python's spaCy from Ruby via PyCall.

The main new feature in this release is block-based OpenAI API integration. The OpenAI client is implemented directly with `net/http`, with no external gem dependencies.

## Block-based OpenAI integration

In earlier versions, you had to pass configuration every time you called the OpenAI API. The new `with_openai` method lets you reuse the client within a block.

Here is an interesting example. The word "crane" carries entirely different meanings depending on context. We process three sentences combining spaCy's structural analysis with an LLM's semantic interpretation.

```ruby
require "ruby-spacy"

nlp = Spacy::Language.new("en_core_web_sm")

texts = [
  "The crane flew over the lake at dawn.",
  "The crane lifted the steel beam to the third floor.",
  "She learned to crane her neck to see over the crowd.",
]

nlp.with_openai(model: "gpt-4o-mini") do |ai|
  nlp.pipe(texts).each do |doc|
    puts doc.text
    doc.each do |token|
      printf "  %-12s %-8s %-8s\n", token.text, token.pos_, token.dep_
    end

    result = ai.chat(
      system: "You are a linguist. Given the linguistic analysis, explain the meaning of 'crane' in one sentence.",
      user: doc.linguistic_summary
    )
    puts "=> #{result}\n\n"
  end
end
```

spaCy correctly classifies "crane" as NOUN in the first two sentences and VERB in the third. Passing that structural analysis to the LLM via `linguistic_summary` yields context-sensitive interpretations:

> In this sentence, "crane" refers to a type of large, long-legged bird known for its graceful flight.

> In this context, "crane" refers to a large, often mechanical device used for lifting heavy objects.

> In this sentence, "crane" is a verb meaning to stretch or extend one's neck in order to see something better, particularly over an obstruction like a crowd.

`linguistic_summary` packages spaCy's analysis -- tokens, named entities, noun chunks, and sentence boundaries -- as JSON, ready to pass directly to an LLM. This makes it straightforward to combine spaCy's structural analysis with LLM reasoning.

