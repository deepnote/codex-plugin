---
name: deepnote-mcp
description: Use when a task mentions Deepnote, the Deepnote MCP server, Deepnote projects, workspaces, notebooks, blocks, integrations, or notebook runs.
---

# Deepnote MCP

## When To Use Deepnote

Use the Deepnote MCP server as the primary interface for hosted Deepnote state. Prefer it over browser automation, screenshots, ad hoc HTTP calls, or local filesystem guesses whenever the user asks about Deepnote projects, notebooks, blocks, integrations, search, or notebook runs.

If the Deepnote MCP server is not available in the current session, say that clearly and ask the user to connect or configure it. The hosted endpoint is `https://deepnote.com/mcp` and authenticates with a bearer token. Do not pretend to have inspected Deepnote state.

The plugin config registers the hosted server under the MCP server id `deepnote`.

## Available Hosted Tools

The hosted Deepnote MCP server currently exposes:

- `search`: search workspace resources across projects, notebooks, blocks, and integrations.
- `list_projects`: list workspace projects, optionally filtered by name.
- `list_integrations`: list workspace integrations, optionally filtered by name or type.
- `get_notebook`: get notebook details, blocks, input variables, and last-run metadata by notebook ID.
- `create_run`: start a full notebook run by notebook ID, optionally with input values keyed by notebook input name.
- `get_run`: fetch run status and snapshot content when available.

## Startup Workflow

1. Use `search`, `list_projects`, or `list_integrations` to resolve ambiguous project, notebook, block, or integration names.
2. Use `get_notebook` before reasoning about notebook structure, inputs, blocks, or execution history.
3. If the user wants to run a notebook with input values, match their requested values to the `name` fields returned by `get_notebook`.
4. Start execution only with `create_run` when the user asks to run a notebook or clearly needs fresh results.
5. Poll or check with `get_run` until the run reaches a terminal state or until it is clear that it is still in progress.
6. Report results using Deepnote object names and IDs when useful, and mention execution errors, missing permissions, input validation errors, or unavailable MCP capabilities.

## Safety Rules

- Do not expose the bearer token or any secret values from integrations or notebook inputs. Refer to secret names only.
- Avoid downloading or printing large datasets. Sample, summarize, or aggregate data unless the user explicitly asks for an export.
- Treat notebook execution as potentially stateful and costly. The hosted MCP `create_run` tool starts a notebook run, not a single-cell edit or targeted cell run.
- Run input overrides apply to one run only. Do not claim they changed notebook defaults.
- The hosted MCP toolset is mostly read/search plus notebook execution. Do not claim to edit notebooks, projects, integrations, permissions, schedules, or publishing through the Deepnote MCP server unless such tools are exposed in the current session.

## Response Style

Keep responses grounded in Deepnote state: project name, notebook name, cell or block labels, execution status, and relevant links when the MCP server provides them. If a task cannot be completed through the Deepnote MCP server, explain the missing capability and offer the nearest safe next step.
