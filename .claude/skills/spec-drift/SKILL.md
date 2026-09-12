---
name: spec-drift
description: Runs the spec-drift-detector subagent — compares README, CLAUDE.md, specs and landing page copy with the code and reports outdated, missing or orphaned statements. Manual via /spec-drift, optionally with a doc filename.
disable-model-invocation: true
context: fork
agent: spec-drift-detector
---
Check documentation drift. Scope: $ARGUMENTS
Without an argument, check all docs named in your agent definition.
Return only the report in the format from your agent definition.
