---
title: "wp2txt: Caching and Category Extraction"
date: 2026-02-21
tags: [software, nlp, wp2txt]
description: "wp2txt 2.1, a command-line Wikipedia text extractor in Ruby, now with SQLite caching, Ractor parallelism, and category extraction."
---

I released [wp2txt](https://github.com/yohasebe/wp2txt) version 2.1. wp2txt is a command-line toolkit for extracting text from Wikipedia dump files. I first wrote it in 2012, and have been maintaining it since.

The main competitor in this space is [WikiExtractor](https://github.com/attardi/wikiextractor), a Python tool with a much larger user base. With this release, I aimed to match or exceed WikiExtractor's processing speed while offering capabilities it does not have. Here are the changes and new features in this version.

- **SQLite-based caching** for parsed data, category hierarchies, and multistream indexes. What used to take minutes to parse on every run now loads in seconds.
- **Ractor parallel processing** on Ruby 4.0+, achieving roughly 2x speedup with a lower memory footprint than process-based parallelism.
- **Template expansion**: common Wikipedia templates like dates, unit conversions, and coordinates are now resolved into readable text.
- **Category-based extraction**: pull all articles belonging to a Wikipedia category, with configurable subcategory depth.
- **Incremental downloads**: large dump files can be resumed from where they left off.

If you are interested in working with Wikipedia text data for research or experiments, try `gem install wp2txt`.
