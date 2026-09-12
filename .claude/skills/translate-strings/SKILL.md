---
name: translate-strings
description: Runs the translator subagent — fills missing or stale de/da/fr/it entries in Shared/Localizable.xcstrings and AppShortcuts.xcstrings in the Solar Lens tone and returns a diff summary. Manual via /translate-strings, optionally with a key substring or language code. (Successor of the legacy /translate command; build in Xcode first if new keys were just added in code.)
disable-model-invocation: true
context: fork
agent: translator
---
Translate missing strings. Filter: $ARGUMENTS
Without an argument, process all candidates in both .xcstrings files.
Update the files in place and return only the summary in the format from your agent definition.
