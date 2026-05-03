---
name: deepnote-notebooks
description: Use when reading, reviewing, inspecting, or reasoning about hosted Deepnote notebooks, blocks, inputs, SQL, Python, or notebook outputs through the Deepnote MCP server.
---

# Deepnote Notebooks

## Notebook Inspection Workflow

1. Resolve the target notebook with `search` or project context before using `get_notebook`.
2. Read the notebook with `get_notebook` before answering questions about structure, inputs, blocks, or last-run state.
3. Preserve distinctions between block types, notebook inputs, code, SQL, markdown, and metadata in your reasoning.
4. When reporting inputs, include the input `name`, `type`, current `value`, and `label` when useful.
5. When asked to review or explain a notebook, ground the answer in specific notebook/block names or IDs when useful.
6. If the user asks for an edit, say whether the currently exposed Deepnote MCP tools support that edit. The hosted toolset currently does not expose notebook write tools.

## Code And Output Handling

- Before suggesting code changes, inspect nearby blocks for imports, shared variables, SQL connections, inputs, and upstream assumptions.
- Prefer deterministic notebook code. Avoid hidden global state, implicit external files, or hard-coded credentials.
- Do not claim an edit was applied unless a write-capable tool is available and reports success.
- If you run a notebook, pass requested input values through `create_run.inputs` using the input `name` fields returned by `get_notebook`, then capture run status with `get_run` and summarize snapshot content or errors when available.
- Run input values do not change the notebook's saved default input values.
- For SQL blocks, preserve the existing connection or data source in recommendations unless the user asks to move it.

## Review And Cleanup

Use Deepnote MCP reads to verify notebook structure before making claims. If execution was not run, say so plainly and mention the remaining risk. For larger reviews, summarize relevant sections rather than listing every block.
