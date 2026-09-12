---
name: privacy-review
description: Runs the privacy-invariant-reviewer subagent — checks a change against ADR-001/ADR-006 (credentials, measurements and rule contents never leave the device; the server is only a push alarm clock). Manual via /privacy-review, optionally with a commit range or path as argument.
disable-model-invocation: true
context: fork
agent: privacy-invariant-reviewer
---

Review the current Solar Lens change against the privacy invariant.

Scope: $ARGUMENTS

If no argument is given, review the working tree (staged and unstaged against HEAD); if it is
clean, review the last commit. An argument may be a commit range, a commit hash, a path
(e.g. `Solar Lens Server/` or `Solar Lens iOS/Automations/Runner`), or the word `all` — for
`all`, audit every file on the client→server boundary and the whole `Solar Lens Server/src/`
tree regardless of the diff.

Return only the report in the format defined in your agent definition, ordered by severity.
