---
title: "Looking for a Multi-Account Email Solution"
date: 2026-06-05
tags: [software, meta]
description: "Multi-account email aggregation used to be a normal thing. It quietly stopped being normal. Notes on what changed, and on reviving a small extension of mine."
---

There was a time when running several email accounts through one inbox was the obvious thing to do. Gmail would pull mail from your Yahoo account, or your school or work address, over POP, and you could send from those addresses too. One inbox, many addresses.

That was a few years ago. Gmail has been winding down its "Check mail from other accounts" feature and signaled that further changes are coming. Microsoft has tightened authentication, and the old way of pulling Outlook addresses into Gmail no longer works. Each provider has retreated into its own walled garden.

For someone with email spread across several services, there are few good options now. Cloud-side aggregators have mostly vanished, and local clients come with their own trade-offs, most notably being tied to a specific device.

Back in 2022 I worked through this and moved to [Fastmail](https://fastmail.com). It is paid, but it handles the multi-address case cleanly. It is independent of the big platforms, lets you host your own domain, and sticks to open standards. I also built a small Chrome extension on the side, [Fastmail Plus](https://chromewebstore.google.com/detail/fastmail-plus/ibgnnkojbkconppocnmdobeodcaijmfm), to smooth over a few UI quirks of my own. It had sat untouched for a long stretch. I brought it up to date with the current UI this week.

![Fastmail Plus browser extension banner: large "Fastmail Plus" logo on a blue background, with a small screenshot of the Fastmail web UI showing the extension's panel listing features like Quick search mode switch, Cursor key navigation, Extra shortcut keys, Non-clutter viewing mode, and Reading pane control buttons. The tagline reads "A browser extension to make Fastmail web UI more usable and productive"](fastmail-plus.png)

Authentication standards have been tightening across the industry, and POP-based bridges are being phased out. Email itself is not going anywhere, but the way to handle several addresses now is to pick a single host and live there.
