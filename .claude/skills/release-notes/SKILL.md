---
name: release-notes
description: Runs the release-notes-writer subagent — App Store "What's New" notes in five languages from the git history since the previous release tag, saved under marketing/release-notes/. Manual via /release-notes, optionally with a tag or commit range.
disable-model-invocation: true
context: fork
agent: release-notes-writer
---
Write the release notes. Range: $ARGUMENTS
Without an argument, use the commits since the previous `release/*` tag.
Save the file and return the five-language notes, the path, and what you left out as internal.
