---
title: "Whisper Stream: A Unix Building Block for Speech"
date: 2026-04-12
tags: [software, ai]
description: "Whisper Stream: a single-file bash script that turns a microphone into a text stream via OpenAI or whisper.cpp, for Unix pipelines."
---

[Whisper Stream](https://github.com/yohasebe/whisper-stream) is a bash script that records speech, detects silence between utterances using sox, and sends each chunk to either OpenAI's transcription API or a local whisper.cpp model for transcription. I originally wrote it in the summer of 2023 and have not touched it much since. Recently I dusted it off and pushed a v2.0.0 update, mainly to make it more useful as a component in Unix pipelines.

## What it does

The script listens to the microphone, uses sox's silence detection to segment the audio into natural utterances, and transcribes each one. The key design constraint is that it is a single bash file with no dependencies beyond sox, curl, and jq (or whisper.cpp for local use). No Python, no Node, no virtual environment.

![Whisper Stream in action](whisper-stream-demo.gif)

The v2.0.0 update adds:

- **`--stdout` and `--jsonl` modes** that skip all side effects (clipboard, file save, banners) and emit transcriptions directly to stdout. This makes the script pipe-native.
- **Local backend** via whisper.cpp — runs offline with no API cost, making always-on dictation practical.
- **Speaker diarization** through OpenAI's newer transcription models.

## Why it matters as a building block

The `--stdout` and `--jsonl` modes are the important part. A speech-to-text tool that writes to stdout and nothing else can be composed with other programs. Because it is a regular Unix filter, you can build things on top of it without touching the source:

```bash
# send a desktop notification when someone says "urgent"
whisper-stream --stdout | grep --line-buffered -i "urgent" | while read -r line; do notify-send "$line"; done

# feed every utterance into an LLM
whisper-stream --jsonl | jq -r '.text' | your-llm-cli
```

A slightly more involved example: a wake-word assistant. The script listens continuously. When it hears a keyword, it plays a short beep to signal readiness, then sends the next utterance to an LLM.

```bash
whisper-stream --stdout | while read -r line; do
  if echo "$line" | grep -qi "hey computer"; then
    # next line from the pipe is the follow-up utterance
    read -r command
    echo "$command" | your-llm-cli
  fi
done
```

There is a brief pause between saying the wake word and seeing a response -- a few seconds while the utterance is transcribed. But it runs on macOS and Linux alike, and I can see it working on a Raspberry Pi with a microphone.