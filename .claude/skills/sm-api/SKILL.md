---
name: sm-api
description: Runs the solar-manager-api-explorer subagent — answers a question about the Solar Manager API from the local swagger files and the app's client code, or diffs two swagger versions. Manual via /sm-api <question | diff <old> <new>>.
disable-model-invocation: true
context: fork
agent: solar-manager-api-explorer
---
Question about the Solar Manager API: $ARGUMENTS
If the argument starts with `diff`, compare the two named swagger files (or the two newest in externals/sm_api_swaggers/) and mark which changes affect the app.
Answer in the concise format from your agent definition; never paste whole schemas.
