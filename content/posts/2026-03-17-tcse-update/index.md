---
title: "TCSE: Entity Search and 6,400 Talks"
date: 2026-03-17
tags: [software, nlp, linguistics]
---

I have been working on a round of updates to [TCSE](https://yohasebe.com/tcse) (TED Corpus Search Engine), a search tool for TED Talk transcripts with translations in 34 languages. It started as a teaching and research tool for corpus linguistics, and has grown into something with over 6,400 searchable talks.

This update focused on three areas: search capabilities, performance, and reducing external dependencies.

**Search**

- Named entity recognition is now integrated into the search. You can search for patterns like `%PERSON said` or `%ORG announced`, and combine entity types with POS filters.
- A new collocation network visualization shows word associations as an interactive force-directed graph. Collocation statistics include mutual information, t-score, and difference of proportions.
- Construction search has been reorganized, with NER-based patterns added alongside the existing grammatical pattern categories.
- KWIC (Key Word In Context) concordance view is now available as an alternative display mode.

**Performance**

- Collocation network queries went from 31 database calls to 2 batch queries, reducing response time from around 10 seconds to 1-2 seconds.
- Composite database indexes on the token table improved advanced search speed.
- Talk search now uses pre-computed tsvector full-text search instead of on-the-fly keyword aggregation.

**Infrastructure**

- All JavaScript and CSS dependencies (jQuery, Bootstrap, D3.js, hls.js) are now bundled locally instead of loaded from CDNs.
- The UI now supports four languages: English, Japanese, Chinese, and Korean.

Tomorrow I am presenting a study on English adjective subjectivity and construction selection at the JAECS Lexicography SIG workshop, and some of the corpus data behind that study comes from TCSE.
