---
title: "Named Entities as Typed Variables in Constructions"
date: 2026-04-02
tags: [linguistics, nlp, research, tcse]
description: "Treating named entities as typed variables in construction grammar search -- %PERSON said, X since %EVENT -- now in TCSE."
---

One of the core ideas in construction grammar is that linguistic knowledge consists of form-meaning pairings at every level -- from individual morphemes to abstract clause patterns. Many constructions have open slots that speakers fill with words of a certain type. "Give X a Y" wants a recipient and a theme. "The more X, the more Y" wants two scalar expressions.

What if one of those slots expects a named entity -- a person, a place, a historical event? Traditional corpus tools can find word patterns, but they have no way to ask for "a country name" or "a famous person".

[TCSE](https://yohasebe.com/tcse) (TED Corpus Search Engine) recently added support for `%ENTITY` notation in its advanced search, which treats named entity types as typed variables. `%PERSON` matches any person name, `%GPE` matches any country or city, `%ORG` matches any organization. See the [documentation](https://yohasebe.github.io/tcse-doc/searching-for-words/named-entity-search/) for the full list of supported types. Under the hood, the feature uses spaCy's NER annotations, which are stored for every token in the corpus of 6,400+ TED Talks.

This turns out to be useful for finding constructions that would be hard to locate with plain keyword search. Let me show a few examples.

## `X since %EVENT`

Named events -- wars, depressions, revolutions -- serve as fixed points on a historical timeline that speakers use to anchor claims about the present. The construction pairs *since* with a named event and treats the event as a temporal benchmark.

- the worst humanitarian crisis **since World War II** [[source]](https://yohasebe.com/tcse/t/100183/24321/1/sentence/0/f/f)
- the greatest transformation **since the Industrial Revolution** [[source]](https://yohasebe.com/tcse/t/48495/80643/1/sentence/0/f/f)
- the greatest debt crisis **since the Great Depression** [[source]](https://yohasebe.com/tcse/t/2859/129968/1/sentence/0/f/f)
- the first human to cross the channel by land **since the Ice Age** [[source]](https://yohasebe.com/tcse/t/61644/65370/1/sentence/0/f/f)

The interesting thing here is what `%EVENT` lets us filter out. A search for *since* alone returns an enormous set of hits -- "since 1973", "since last year", "since we started" -- most of which anchor to a date, a time, or a clause rather than to a named occurrence. Swapping in `%EVENT` isolates a genuine subcategory: the construction where the benchmark is a named happening of any scale that the audience is expected to recognize. That is a distinction you cannot draw with keywords or part-of-speech tags.

## `the %PERSONs`

English uses the plural form of a proper noun in several ways. "The Smiths" can mean a specific family. The construction I want to highlight here is different: the name is pluralized not to pick out a family but to stand for a type -- "people like X".

- they might become **the Darwins of the 21st century**, studying urban evolution [[source]](https://yohasebe.com/tcse/t/64774/62028/1/sentence/0/f/f)
- It is **the Shackletons of our offices** rather than **the Amundsens**, who serve as role models, who get promoted and who get rewarded. [[source]](https://yohasebe.com/tcse/t/130848/607796/1/sentence/0/f/f)
- Her name was Dottie and he made a vow that day to always know **the Dotties in his life**. [[source]](https://yohasebe.com/tcse/t/70380/54571/1/sentence/0/f/f)
- helping **the Sams of the world** [[source]](https://yohasebe.com/tcse/t/66921/58207/1/sentence/0/f/f)

What typically marks this usage is a restricting phrase like *of the world*, *of the 21st century*, *of our offices*, or *in his life*, which anchors the name to a type rather than a household. In the Darwin, Shackleton, and Amundsen examples, the names are famous ones and the construction invokes the category they stand for -- urban ecologists inheriting a scientific tradition, or the reckless explorer versus the methodical one as office archetypes. The Dottie and Sam examples are different: Dottie is a specific person the speaker's friend had noticed in passing, and Sam is the speaker's own name, used to refer generically to people in situations like hers. In neither case does the audience need to identify the individual behind the name. The construction itself signals "read this as a type, not an individual".

## `meanwhile in %GPE`

Place names participate in constructions too. `meanwhile in %GPE`[^gpe] is a discourse marker that introduces a parallel scene -- "while that was happening here, over in X something else was going on". It is a narrative device speakers use to cut between settings.

[^gpe]: `%GPE` stands for *Geopolitical Entity* in spaCy's NER scheme. It covers countries, cities, and other place names with political boundaries, as distinct from `%LOC`, which is used for non-political geographic locations like mountain ranges and bodies of water.

- **Meanwhile, in New York City**, the NYPD has driven police cars equipped with license plate readers past mosques. [[source]](https://yohasebe.com/tcse/t/2149/178141/1/sentence/0/f/f)
- **Meanwhile in Constantinople**, Anna fought her own battle. [[source]](https://yohasebe.com/tcse/t/25874/368709/1/sentence/0/f/f)
- **Meanwhile, in Australia**, you can find a second type of mammal -- marsupials. [[source]](https://yohasebe.com/tcse/t/24468/480990/1/sentence/0/f/f)
- **Meanwhile, in Copenhagen** we're actually expanding the bicycle lanes. [[source]](https://yohasebe.com/tcse/t/634/519831/1/sentence/0/f/f)

One more advantage of NER search is worth pointing out here: multi-token entities are treated as single units. Among the examples above, *Copenhagen* and *Constantinople* are single tokens, while *New York City* is three. spaCy's NER marks all of them as a single GPE, so `%GPE` matches the whole span in each case. A search for `meanwhile in %GPE` does not need to worry about how many words the place name has. That kind of chunking is essential when the slot has to accept anything a speaker might name.

## Why this matters

None of the constructions above is exotic. Linguists have studied many patterns like them. What is new is the ability to find them systematically across a curated corpus without knowing the filler words in advance.

For a construction grammarian, the ability to specify a slot as "any person name", "any place name", or "any named event" matches the way we think about constructions in the first place -- as schemas with typed variables, not as lists of word combinations. NER search lets the search interface catch up to the theory.
