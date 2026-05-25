---
title: "Conversation Memory That Stays on Your Laptop"
date: 2026-05-25
tags: [software, ai, monadic-chat, privacy]
description: "Monadic Chat now uses a local multilingual embedding model and a local vector DB. Indexing and retrieval of past chats happen entirely on the machine, without going through a cloud embedding API."
---

You remember talking with the AI assistant about something months back, like a config you sorted out or a paper you summarized. But finding it again means figuring out which past chat to even open. Most LLM clients don't search across your past chats at all, and the ones that do tend to ship your messages to a cloud embedding API just to make them searchable.

The latest [Monadic Chat](https://github.com/yohasebe/monadic-chat), an AI chat platform I work on, moves this end to end onto your machine.

The earlier setup used OpenAI's `text-embedding-3-large` for the help system and PDF knowledge base, with PGVector for storage. It worked for static documents, but extending the same path to conversations would have meant every chat passing through a cloud embedding endpoint just to be findable later. I wanted to avoid that. The new embedding pipeline is fully local:

- An embeddings container running [`multilingual-e5-base`](https://huggingface.co/intfloat/multilingual-e5-base) (sentence-transformers)
- A [Qdrant](https://qdrant.tech/) container holding the vectors
- A two-level embedding scheme: a summary per conversation, plus the individual turns inside it

Qdrant is an open-source database designed for embeddings: it stores them and searches by similarity in meaning rather than exact wording.

The same store also holds PDF and document content if you've imported any, so search works uniformly across whatever you've put into the knowledge base.

Search is cascade: a query first hits conversation summaries, then drills into the matching conversations turn by turn. The retrieval is wired up as a RAG tool too, so past content can be pulled into the current chat as context when the model decides it's useful.

And if you pick an Ollama-backed model for the chat itself, it runs locally too.
