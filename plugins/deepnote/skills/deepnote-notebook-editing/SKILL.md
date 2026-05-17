---
name: deepnote-notebook-editing
description: Use when creating Deepnote projects or notebooks, adding blocks or cells, scaffolding notebook content, inserting SQL/code/markdown/input blocks, or otherwise editing notebook structure through the Deepnote MCP server.
---

# Deepnote Notebook Editing

## When To Use

Use this skill when the user asks Codex to create a Deepnote project, create a notebook, add a block or cell, scaffold starter notebook content, insert code, SQL, markdown, or input blocks, or make a structural notebook edit supported by the current MCP write tools.

The current editing surface covered by this skill is:

- `create_project`: create a new project. Requires `name`; accepts optional `folderId`.
- `create_notebook`: create an empty notebook in a project. Requires `projectId`; accepts optional `name`.
- `create_block`: create a block in a notebook. Requires `notebookId` and `type`; accepts optional `content`, `metadata`, `position`, `includeNotebookBlockIds`, and SQL-only `integrationId`.

## Editing Workflow

1. Resolve ambiguous names and IDs before writing. Use `get_me` for workspace identity, `search` or `list_projects` for projects/notebooks, `get_notebook` for current block order, and `list_integrations` for SQL connections.
2. Treat `create_project`, `create_notebook`, and `create_block` as non-idempotent. Repeating the same call creates another resource.
3. Use `create_project` only when the user wants a new project. A created project includes a default empty notebook.
4. Use `create_notebook` only when adding an empty notebook to an existing project. It does not accept starter blocks; create blocks afterward with `create_block`.
5. Use `create_block` for each new block. Omit `position` to append, or pass a zero-based `position` when placement matters.
6. Pass `includeNotebookBlockIds: true` when the final block order matters, especially for ordered inserts or multi-block scaffolds.
7. Verify meaningful edits with `get_notebook` after block creation when order, integration attachment, or multi-block content matters.
8. Do not run the notebook after editing unless the user explicitly asks for execution.

## Block Creation Guidance

Choose the block `type` that matches Deepnote's block vocabulary. Common types include `code`, `sql`, `markdown`, input blocks such as `input-text`, `input-select`, `input-checkbox`, and text-cell variants such as `text-cell-h1`, `text-cell-p`, and `text-cell-callout`.

For SQL blocks:

- Resolve the integration first with `list_integrations` when the user gives a connection name.
- Pass the connection as top-level `integrationId`.
- Do not put `sql_integration_id` inside `metadata`.
- Do not pass `integrationId` for non-SQL blocks.

For input blocks, put block-type configuration in `metadata` and keep `content` for the visible/default textual content when applicable. Preserve existing notebook naming and variable conventions when adding inputs near related blocks.

## Response Style

After a successful edit, report the created project, notebook, or block name/ID, plus placement or final block order when relevant. Include Deepnote links when they can be safely constructed with `deepnote-links`.

If a write tool returns an error, surface the user-facing message concisely and name the likely fix: missing permission, missing target resource, invalid block type, invalid position, duplicate notebook name, suspended project, or incompatible SQL integration.
