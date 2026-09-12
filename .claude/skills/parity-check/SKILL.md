---
name: parity-check
description: Runs the platform-parity-checker subagent — traces a feature across iOS, watchOS, tvOS, widgets, complications, Live Activities, AppIntents and CarPlay and reports gaps. Manual via /parity-check <feature>, or without argument for the last change.
disable-model-invocation: true
context: fork
agent: platform-parity-checker
---
Check platform parity for: $ARGUMENTS
Without an argument, derive the feature(s) from the working tree or last commit.
Return only the parity matrix and recommendations in the format from your agent definition.
