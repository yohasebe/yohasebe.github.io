---
title: "Reading Anthropic on Recursive Self-Improvement"
date: 2026-06-06
tags: [ai, monadic-chat]
description: "Notes after reading Anthropic's piece on AI building AI, on why I keep Monadic Chat multi-provider, and on what is left of the human side of development."
---

Anthropic recently posted a piece called ["When AI builds itself"](https://www.anthropic.com/institute/recursive-self-improvement) on their institute site. It is about recursive self-improvement: the point at which an AI system can autonomously design and develop its own successor. They are explicit that we are not there yet, and that this is not inevitable. It also lays out evidence that the direction is real. As of May 2026 they report that more than 80% of the code merged into Anthropic's codebase is written by Claude, and the length of tasks AI can reliably complete is doubling roughly every four months. Research taste and alignment, they note, are the parts that remain hardest for AI.

On policy, Anthropic say they would support a coordinated international pause under certain conditions, specifically if verification systems existed so frontier developers could confirm others had actually stopped. A unilateral pause by one lab, they argue, would mainly just change who the front-runner is.

I work on [Monadic Chat](https://github.com/yohasebe/monadic-chat), a locally hosted AI chat platform. I have kept it multi-provider deliberately. Today it routes to seven hosted providers and one local runtime:

- OpenAI (US)
- Google (US)
- xAI (US)
- Anthropic (US)
- Cohere (Canada)
- Mistral (France)
- DeepSeek (China)
- Ollama (local, not tied to any jurisdiction)

![Monadic Chat's System Settings panel: the Base App dropdown lists the supported providers (OpenAI, Anthropic, xAI, Google, Cohere, Mistral, DeepSeek, Ollama). To the right is an agent flow diagram: User Input goes through System Prompt to gpt-5.4, with Tools (Library Search, File Operations), Message History, and Features (Web Search) panels feeding in and out](monadic-chat-providers.png)

The reason is less a principle than a practical hedge. Without an international coordination framework in place, regulation, if and when it comes, is likely to take different shapes across providers, jurisdictions, and timelines. If a user has only one route to the AI work they want to do, their work can stall when those rules change first. More routes mean more flexibility as things change.

At the same time, what Anthropic are calling for seems reasonable to me. Paying attention to the trajectory and setting up structures that would let humans intervene later is hardly an overreaction.

Over the last few years I have been watching the layers AI handles in development grow. Snippet suggestions, then function coding, then codebase design, technology choice, execution, testing, debugging. I built [ccm for tmux](https://github.com/yohasebe/tmux-ccm) on the working belief that the last thing left on the human side is attention and judgment. The Anthropic piece argues that even that layer is starting to move.

There is not much an individual developer can do at this scale. Most of what I build either reinvents something that already exists or gets superseded by a larger project. I keep building anyway. Honestly, the AI built on top of large language models is becoming a more and more complete black box for ordinary users. Before it fully gets there, I want to grasp what is happening, as far as I can, for myself. I cannot enter the model development race. But building my own tools is itself a way of keeping some control on my side, however small. At least I can see what is happening firsthand.
