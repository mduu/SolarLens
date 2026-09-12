---
name: refine-story
description: Runs the story-refiner subagent — turns a backlog idea, issue or request into a story draft following specs/stories/_template.md with open questions and concrete tasks. Manual via /refine-story <idea, backlog title or issue number>.
disable-model-invocation: true
context: fork
agent: story-refiner
---
Work the following idea into a story: $ARGUMENTS
If the argument is a backlog title, start from that section in specs/backlog.md; if it is an issue number, read the issue.
Write exactly one new file under specs/stories/ and return the path, open questions and ADR assessment.
