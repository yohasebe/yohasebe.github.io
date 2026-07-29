---
title: "jReadability and jWriter"
date: 2026-07-14
tags: [software, linguistics, education, ai]
description: "Two long-running tools for Japanese language education, built with Jae-Ho Lee: one measures text readability, the other evaluates learner writing and now gives LLM-based feedback."
---

For many years I have worked with [Jae-Ho Lee](https://gsjal.jp/lee/) (Waseda University) on two tools for Japanese language education. Both predate the current wave of generative AI by a long way, and one of them has since taken it on board.

The first is [jReadability](https://jreadability.net), which measures how difficult a Japanese text is to read. You paste in a passage and it returns a readability level, along with a breakdown of the features behind that score. The underlying measure was derived from levelled corpora -- texts graded by difficulty -- and the system has been in use since the early 2010s, mostly by teachers choosing or adapting materials for their students.

The second is [jWriter](https://jreadability.net/jwriter), which evaluates writing by learners of Japanese. It estimates a learner's proficiency from a submitted essay, using a regression model built on I-JAS, a large corpus of learner writing. Alongside the level estimate, it reports diagnostic features: vocabulary diversity, the use of Sino-Japanese vocabulary, average sentence length, and a measure of logical structure. None of this involves a language model. It is corpus statistics, and it has worked in much the same way for years.

Recently we added LLM-based feedback to jWriter. There are four functions: written comments on the essay, sentence-level suggestions, a rewrite for comparison, and an evaluation of the learner's own revision -- so the process does not end with a score, but continues through revising and being re-evaluated. The rewrite, by the way, is displayed but cannot be copied: it is there to learn from, not to hand in.

The part that matters in the design is that the language model does not work from the raw essay alone. The proficiency estimate and the diagnostic features computed by the older machinery are passed to it as part of the prompt. This is meant to keep the evaluation more consistent and grounded than leaving it to whatever a general chat model happens to produce on a given run. Corpus-based work from before generative AI may not simply be replaced by language models; its role may change instead, giving the models a footing and supporting finer-grained analysis.

I wrote earlier about [a related study](../2026-01-15-ai-human-simplification/index.html) comparing how AI and human editors simplify text. The suggestion there was that AI and human language processing have different strengths and can complement each other. The same idea underlies these tools: not AI as a replacement for teachers, but as something that works alongside them.

---

Lee, J.-H. and Y. Hasebe. 2020. Quantitative Analysis of JFL Learners' Writing Abilities and the Development of a Computational System to Estimate Writing Proficiency. *Learner Corpus Studies in Asia and the World* 5, 105-120. [PDF](https://doi.org/10.24546/81012493)

Lee, J.-H. and Y. Hasebe. 2020. Readability Measurement of Japanese Texts Based on Levelled Corpora. In I. Srdanović and A. Bekeš (eds.), *The Japanese Language from an Empirical Perspective: Corpus-Based Studies and Studies on Discourse*. Ljubljana: Ljubljana University Press, 143-168. [DOI](https://doi.org/10.4312/9789610602170)

Hasebe, Y. and J.-H. Lee. 2015. Introducing a Readability Evaluation System for Japanese Language Education. Proceedings of the 6th International Conference on Computer Assisted Systems for Teaching & Learning Japanese (CASTEL/J). [PDF](assets/docs/Hasebe_Lee_2015_CASTELJ.pdf)

Hasebe, Y. and J.-H. Lee. 2025. Divergent strategies in text simplification: A comparative analysis of AI and human approaches in language processing. *Intercultural Pragmatics* 22(2), 203-230. [DOI](https://doi.org/10.1515/ip-2025-2002)
