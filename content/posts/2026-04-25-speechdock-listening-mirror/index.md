---
title: "Watching Words Appear: Real-time STT and L2 Listening"
date: 2026-04-25
tags: [software, speechdock, education, linguistics, cognition]
description: "Why captions can hurt listening practice, and how the lag in real-time STT might be useful instead."
---

When we learn a foreign language, listening is, for many learners, the skill that resists practice the most. Reading and writing happen on our schedule. Speaking we control. But listening means catching speech as it goes by, in real time, with no rewind.

The most common aid is captions. Watch a video with subtitles and you can follow along. But captions can undermine the very thing we are trying to practice. Visual information tends to take priority over audio in our cognitive processing, and when the two arrive together, the work of extracting meaning from sound alone is reduced. Since captions are timed to the audio -- or slightly ahead -- the listener ends up reading rather than listening.

To address part of this, [TCSE](https://yohasebe.com/tcse/) has long had a fullscreen mode (described in [an earlier post](../2026-04-18-tcse-fullscreen/index.html)) where no transcript shows during playback; only the previous and current lines appear the moment you pause. The listener has to attempt interpretation first, and only then check. But the answer-checking happens at sentence boundaries. You hear a whole sentence, decide what you think it said, then pause to verify. The granularity is coarse.

[SpeechDock](https://github.com/yohasebe/speechdock) is a Mac app I have been building for speech-to-text and text-to-speech tasks. Unlike most STT apps, it can take its input from the microphone, the system audio mix, or the audio from a specific application. One of its modes runs that input through real-time STT (either macOS-native or a cloud provider) and displays the result as a HUD overlay on top of whatever is on screen.

<video controls preload="metadata" src="ask-nasa-transcription.mp4" style="max-width:100%;"></video>

*SpeechDock real-time transcription overlaid on NASA's [Ask NASA: How Will Astronauts Dig on the Moon?](https://images.nasa.gov/details/NHQ_2020_0127_AskNASA┃%20How%20Will%20Astronauts%20Dig%20on%20the%20Moon) (00:16–00:46, public domain). The demo uses macOS's native STT, with VLC's audio output specified as the SpeechDock input source.*

Real-time STT cannot show text at the same moment as the audio. There is always some lag in our verbal communication, for that matter: speech has to be heard, segmented, recognized, and rendered. And there is always the possibility of revision when later input changes the parse.

Real-time STT makes this incremental, revisable parsing visible. The HUD is not a transcript that hands you the answer; it shows a process that mirrors the cognition you are trying to develop, unfolding before your eyes.

Whether this kind of tool actually helps L2 learners improve their listening is an open empirical question. If anyone wants to design a proper study together, please get in touch.
