---
title: "The Cloud Sees PERSON, You See Your Name"
date: 2026-05-18
tags: [software, ai, monadic-chat, privacy]
description: "Monadic Chat detects personal info locally and replaces it with typed placeholders before sending to cloud LLMs. You still see your original text; only the placeholder version crosses the network."
---

You have something personal to ask the AI assistant. A draft email with names in it. A summary of a doc with email addresses or phone numbers. You want the LLM's help but pasting it straight into a cloud provider stops you. So you redact by hand, paste the masked version, mentally translate back when reading the response. Tedious, and the LLM doesn't know what kind of thing you redacted.

The latest [Monadic Chat](https://github.com/yohasebe/monadic-chat), an AI chat platform I work on, does this for you, invisibly. You type the original. Before send, a local detector replaces PII (personally identifiable information) with typed placeholders. The LLM gets `<<PERSON_1>>`; you keep seeing the real name on screen. When the response comes back, any placeholders it preserved are restored to the original values for display.

![Monadic Chat Chat Plus conversation: a user message asking for a draft email to "Kevin Park" with office number "555-123-4567", and the assistant's email reply containing the same values. Both occurrences of the name and phone number are visibly highlighted, indicating the privacy filter detected them as PII](privacy-filter.png)

![Privacy Registry modal listing two mappings: PERSON_1 to Kevin Park (PERSON), PHONE_NUMBER_1 to 555-123-4567 (PHONE_NUMBER). A note above the table reads "This list is held in memory only and is cleared when the conversation is closed. Copy is intentionally disabled to avoid accidental disclosure."](privacy-dashboard.png)

The detector runs in its own Docker container with Microsoft Presidio + spaCy. Presidio handles pattern-based categories (email, phone, credit card, SSN, IP, URL, and others); a local spaCy NER model handles context-dependent ones (people, organizations). Detection is multilingual, supporting 9 languages.

A few properties that matter:

- **Per-session**: each chat gets its own placeholder registry, in memory. Nothing accumulates as a growing on-disk record of who you've talked about. If you export an encrypted session and import it again later, the registry is restored alongside the conversation, so masking keeps working on follow-up turns.
- **Per-app**: the toggle shows up only on apps where masking makes sense (Chat Plus, Mail Composer, Translate, Second Opinion). Apps focused on code generation or media output don't expose it, since their inputs rarely carry personal information.
- **Fail-closed**: in the unlikely event the privacy container can't run, the main chat still works, but background calls that would send extra text to the cloud (title suggestion, second opinion) are skipped rather than sent without masking.
- **Detection is probabilistic**: pattern-based categories (emails, phones, etc.) are caught reliably, but the NER paths for names and organizations will sometimes miss novel forms or edge cases. The filter substantially reduces what leaves the machine; it doesn't guarantee zero leakage.

The LLM only sees the type label (`<<PERSON_1>>`, `<<EMAIL_1>>`), not the actual value. It knows what kind of thing is hidden, but not which specific one. For rewriting, summarizing, translating, drafting, that level of knowledge is enough. For tasks where the specific value matters, you can just turn the filter off for that session.
