---
name: draft-adr
description: Runs the adr-drafter subagent — drafts an ADR (status Proposed) from a question or commit range following specs/adrs/_template.md and checks it against existing ADRs. Manual via /draft-adr <question or range>.
disable-model-invocation: true
context: fork
agent: adr-drafter
---
Draft an ADR for: $ARGUMENTS
If the argument is a commit range or hash, derive the decision from the diff; otherwise treat it as a question.
Write exactly one new file under specs/adrs/ and return path, decision, affected ADRs and follow-up updates.
