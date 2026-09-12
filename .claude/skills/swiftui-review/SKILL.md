---
name: swiftui-review
description: Runs the swiftui-conventions-reviewer subagent — view naming and purity, component placement, formatting helpers, semantic colors, typography, localization. Manual via /swiftui-review, optionally with a commit range or path.
disable-model-invocation: true
context: fork
agent: swiftui-conventions-reviewer
---
Review the Solar Lens change against the SwiftUI conventions. Scope: $ARGUMENTS
Without an argument: working tree, or the last commit if clean.
Return only the report in the format from your agent definition.
