---
title: "RSyntaxTree: Tidy Layout"
date: 2026-08-15
tags: [software, linguistics, rsyntaxtree]
description: "RSyntaxTree 1.8 adds a tidy layout setting that packs subtrees closer together, along with a substantial improvement to multilingual rendering."
---

I released [RSyntaxTree](https://yohasebe.com/rsyntaxtree) 1.8. One of the additions is `tidy`, a setting that controls how tightly subtrees are packed.

Until now, every subtree was given a horizontal slot wide enough that it could never meet its neighbours. That is simple and always works, but much of the reserved space goes unused. Each embedded phrase pushes its siblings apart, and trees nest deeply, so even a small structure can come out wider than it needs to be. Here is one from Chomsky (1995: 50), drawn the old way:

<div class="figure-grid">
<div style="width:69.4%">
<img src="tidy-off.svg" alt="A minimalist tree drawn without tidy layout: each subtree keeps a fixed slot, leaving wide gaps between branches" style="width:100%; max-width:none; margin:0" />
<div class="fig-label">off — 969 px</div>
</div>
</div>

Tidy layout measures the actual shape of each subtree and slides neighbours together until they almost touch. There are three levels of packing; here are the first two, at the same scale as the tree above:

<div class="figure-grid">
<div style="width:55.6%">
<img src="tidy-low.svg" alt="The same tree at tidy low: neighbouring subtrees are packed by their outlines" style="width:100%; max-width:none; margin:0" />
<div class="fig-label">low — 772 px</div>
</div>
<div style="width:43.4%">
<img src="tidy-medium.svg" alt="The same tree at tidy medium: subtrees also move into space that neighbours on other rows are not using" style="width:100%; max-width:none; margin:0" />
<div class="fig-label">medium — 597 px</div>
</div>
</div>

The levels differ in how far a subtree may slide under its neighbours. `low` never lets two words overlap horizontally, so no word ends up directly above or below another. `medium` allows it, and that is what narrows the tree: above, *John* and *cause* have ended up one above the other. Neither may pass the other, so the words keep their left-to-right order. `high` drops that last rule and keeps the order only within a row; on this tree it comes out the same width as `medium`, so it is not shown.

How much any of this helps depends on the tree. A balanced tree has little space to recover; a deep branch beside a shallow one has a lot, and `high` needs a more lopsided tree still before it differs from `medium`. For this tree I would use `medium`: it is as tight as the packing gets here, and having *John* sit over *cause* does not make the tree harder to read.

The other main improvement in this release is multilingual rendering. Every font style now falls back to Noto Sans/Serif/Mono CJK, so Hangul and both simplified and traditional Han render in all of them, and Arabic, Hebrew, Devanagari, Thai and Khmer are named explicitly in the font chains. Machines that have those fonts installed now produce the same shapes from the same input. A new `mirror` option flips a finished tree horizontally, for the right-to-left convention used in Arabic and Hebrew. The [example gallery](https://yohasebe.github.io/rsyntaxtree/examples) has a multilingual section showing the same sentence in nine languages, and each example now lists the settings used, so it can be reproduced in the web interface.

---

Chomsky, Noam. 1995. *The Minimalist Program*. Cambridge, MA: MIT Press.
