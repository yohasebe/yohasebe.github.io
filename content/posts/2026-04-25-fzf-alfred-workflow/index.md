---
title: "Filing in Trees, Finding in Fragments"
date: 2026-04-25
tags: [software, meta, macos]
description: "Why filing and finding pull in different directions, and what fzf in Alfred does about it."
---

When I look for something on my computer, the things I remember come in pieces. The folder it might be in. A word from the filename. A topic. They arrive in no particular order. But the standard way to find a file -- open a folder window, descend one level, then another -- demands that I produce them in exactly the right sequence.

I only notice this when I am finding things. When I am putting them away, I am happy to take my time, placing each file somewhere sensible. Filing and finding feel like different kinds of work.

## Filing can wait, finding cannot

Filing can wait. I have a moment to decide which project, which year, which subfolder. Getting it slightly wrong is fine -- I can move the file later.

Finding cannot wait. By the time I notice I want a file, I want it now. Whatever fragments come to mind should be enough.

There are two common ways to organize files in the face of this. Neither works for me.

The first abandons hierarchy: keep everything in one flat space, tag each file, and search by tag. Retrieval is great. But filing becomes a chore. There is no obvious "right place" for a new file, and tagging well takes more discipline than I have. So I file less.

The second commits to hierarchy in both directions: organize as a tree, find by descending the tree. macOS Finder columns invite this. But finding becomes expensive. I have to know the tree to use it, and the fragments that come to mind first are not always at the top. I open the wrong folder, back out, try again -- searching by walking, the slow way.

What both share is the assumption that storage and retrieval should mirror each other. But filing and finding are not the same activity, and forcing them into the same shape makes both worse.

## A way that respects both

What I want is to keep the hierarchy I already have, and search across it with whatever fragments come to mind, in any order.

On macOS, the tool that does this for me is [fzf-alfred-workflow](https://github.com/yohasebe/fzf-alfred-workflow), a small Alfred workflow I wrote some years ago. It plugs [fzf](https://github.com/junegunn/fzf) and [fd](https://github.com/sharkdp/fd) together so any space-separated fragments I type are matched against every path under my home directory, in any order.

![fzf in Alfred, narrowing results as keywords are added](fzf-demo.gif)

The pleasure of using it is less about speed than about a small relief: I no longer have to remember where things are. Filing stays hierarchical, because there is no rush when I file. Finding takes whatever fragments are in my head.

The same asymmetry shows up in language. Lexical concepts are organized hierarchically -- an efficient data structure for organizing the world. But real-time lexical use does not behave like a tree search; it unfolds on a reference-point network, jumping from one anchor to another. The tool feels right because it stops trying to make filing and finding match. They were never going to.
