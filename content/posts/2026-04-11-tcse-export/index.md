---
title: "TCSE: Exporting Search Results"
date: 2026-04-11
tags: [software, linguistics, nlp, research]
---

Over the past year or two, I have received a handful of emails asking for the same thing: could TCSE let users download search results, instead of forcing them to copy and paste hits one by one into a spreadsheet? I agreed every time that it was a reasonable request, put it on my to-do list, and never quite got around to it. That has now finally changed.

[TCSE](https://yohasebe.com/tcse) now has an export feature, currently in beta. You can find the documentation [here](https://yohasebe.github.io/tcse-doc/searching-for-words/export-search-results/).

## Page-by-page export

Each export returns the current page of search results -- around 200 items, matching what you see on the screen. The interface already paginates results 200 per page, so "export what I am looking at" is the natural model.

I deliberately avoided a single-request bulk download of thousands of rows. Both server load and the appropriate use of a corpus built on publicly accessible transcripts argued against it, and keeping each export scoped to one page keeps each request as light as an ordinary page view.

If you need the full set of hits for a high-frequency query, you can simply page through and export each page in turn. A short five-second cooldown sits between exports as a simple throttle against accidental double-clicks and overly eager scripts, but it should not get in anyone's way in normal use.

## What each row contains

On any search results page, a small "Export" button offers two formats:

- **ZIP** — a TSV file containing the rows, plus a `metadata.json` describing the query and the export
- **JSON** — everything in a single JSON file

Each row is not just the matched segment but the matched segment plus **two segments of context before and after**, along with the talk metadata (title, speaker, year, URL, duration). When you search with the Advanced Search syntax, the TSV also includes the part-of-speech, lemma, and dependency label of the matched token. When you have a translation language selected, the translation text is included too.

The TSV is UTF-8 with a byte-order mark, so Excel opens it without garbling non-ASCII characters.

## Use cases

A few things this unlocks for TCSE users:

- **Close reading of hits**: download the hits for a word, construction, or discourse marker and work through them in a spreadsheet or a notebook, annotating by hand or running scripts
- **Statistical work**: load the TSV into R or Python, group by year or speaker, count co-occurrences, build visualizations
- **Teaching material**: build a small custom dataset for a class assignment without having to set up your own corpus pipeline

## Beta status

The feature is live as a beta release. The core functionality is in place, but there may be rough edges to smooth out based on how people actually use it. If you try it out and run into anything odd, or if there is metadata you wish were included but is not, let me know.
