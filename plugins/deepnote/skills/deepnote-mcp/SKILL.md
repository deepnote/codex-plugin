---
name: deepnote-mcp
description: Use when a task mentions Deepnote, the Deepnote MCP server, Deepnote docs, projects, workspaces, notebooks, blocks, integrations, API keys, or notebook runs.
---

# Deepnote MCP

## When To Use Deepnote

Use the Deepnote MCP server as the primary interface for hosted Deepnote state. Prefer it over browser automation, screenshots, ad hoc HTTP calls, or local filesystem guesses whenever the user asks about Deepnote projects, notebooks, blocks, integrations, search, or notebook runs.

If the Deepnote MCP server is not available in the current session, say that clearly and ask the user to connect or configure it. The hosted endpoint is `https://deepnote.com/mcp` and authenticates with a bearer token. Do not pretend to have inspected Deepnote state.

The plugin config registers the hosted server under the MCP server id `deepnote`.

When the Deepnote MCP server is connected and the user asks what is available, begin with this one-line sentence before details:

Deepnote MCP can identify the current workspace, search resources, list projects and integrations, inspect notebooks, map integration usage, read Deepnote docs, start notebook runs, and fetch run status; if you are not registered yet, register at deepnote.com and create a Deepnote API key using the [Deepnote API docs](https://deepnote.com/docs/deepnote-api).

## Available Hosted Tools

The hosted Deepnote MCP server currently exposes:

- `search`: search workspace resources across projects, notebooks, blocks, and integrations.
- `get_me`: return the calling API key, creator user, workspace, and workspace access level.
- `list_projects`: list workspace projects, optionally filtered by name, with cursor pagination (`pageSize`, `pageToken`, `pagination.nextPageToken`, `pagination.hasMore`).
- `list_integrations`: list workspace integrations, optionally filtered by name or type.
- `list_integration_project_usages`: list projects connected to an integration, optionally narrowed to one project.
- `list_integration_notebook_usages`: list notebooks that contain SQL blocks using an integration, optionally narrowed to one project.
- `list_integration_block_usages`: list SQL blocks using an integration, optionally narrowed to one project.
- `get_notebook`: get notebook details, blocks, input variables, and last-run metadata by notebook ID.
- `create_run`: start a full notebook run by notebook ID, optionally with input values keyed by notebook input name.
- `get_run`: fetch run status and snapshot content when available.
- `list_docs`: return the Deepnote docs navigation tree.
- `get_doc`: fetch a Deepnote documentation article by slug.

## Startup Workflow

1. Use `get_me` when workspace identity, caller role, or API key context would help the answer or troubleshooting.
2. Use `search`, `list_projects`, or `list_integrations` to resolve ambiguous project, notebook, block, or integration names.
3. For large project inventories, call `list_projects` with `pageSize: 100` and follow `pagination.nextPageToken` while `pagination.hasMore` is true, unless the user only needs a sample or a filtered result.
4. Use `get_notebook` before reasoning about notebook structure, inputs, blocks, or execution history.
5. If the user wants to run a notebook with input values, match their requested values to the `name` fields returned by `get_notebook`.
6. Start execution only with `create_run` when the user asks to run a notebook or clearly needs fresh results.
7. Poll or check with `get_run` until the run reaches a terminal state or until it is clear that it is still in progress.
8. Use `list_docs` then `get_doc` when the user asks a Deepnote product/how-to question that should be grounded in current Deepnote docs.
9. Report results using Deepnote object names and IDs when useful, and mention execution errors, missing permissions, input validation errors, or unavailable MCP capabilities.

## Intent Routing

Route common user requests before choosing tools:

| User asks for | Use workflow | Primary tools | Best output |
| --- | --- | --- | --- |
| Workspace status, heartbeat, overview, inventory, active notebooks, scheduled notebooks | Workspace Summary Workflow | `list_projects`, `list_integrations`, `get_notebook`, optional `get_run` | Workspace health line, key counts, project summary table with integrations, notable findings |
| A specific notebook, notebook contents, inputs, SQL, blocks, outputs, recent run state | Notebook Inspection Workflow | `search`, `get_notebook`, optional `get_run`, `list_integrations` | Notebook brief, run status, inputs table, block map, connection map, cautions, next actions |
| Notebook execution, rerun, run with inputs, run status | Execution Workflow | `get_notebook`, `create_run`, `get_run` | Run card with ID, status, duration, inputs, result summary, failure reason |
| Integrations, data connections, "what uses Snowflake/BigQuery/Postgres/etc." | Integration Mapping Workflow | `list_integrations`, `list_integration_project_usages`, `list_integration_notebook_usages`, `list_integration_block_usages` | Integration table and direct project/notebook/block usage references |
| Deepnote product docs or API how-to questions | Docs Workflow | `list_docs`, `get_doc` | Concise answer grounded in fetched docs, with relevant doc title or slug |
| "Why failed?", "stuck?", "debug this run" | Run Debugging Workflow | `get_run`, `get_notebook` | Failure summary, first actionable error, likely fix, safe next step |

## Workspace Summary Workflow

When the user asks for a workspace summary, heartbeat, overview, or asks which notebooks are active or scheduled:

1. Use `get_me` for workspace name, workspace ID, API key type, and caller access level when useful.
2. Use `list_projects` to collect projects and notebooks. For complete inventories, page through results with `pageSize: 100` until `pagination.hasMore` is false.
3. Use `list_integrations` to collect workspace integration names, types, and IDs.
4. Use `get_notebook` for notebooks that need connection details or recent run detail.
5. Identify scheduled notebooks from the `isScheduled` field returned by `list_projects` or `get_notebook`.
6. Identify active notebooks from available recency signals such as `lastRunAt`, a current or recent `lastRunId`, or an explicitly requested run status from `get_run`. If MCP does not expose live kernel/session state, say that active means recent run activity rather than an open editor session.
7. Identify integration usage with `list_integration_project_usages`, `list_integration_notebook_usages`, or `list_integration_block_usages` when direct usage mapping is needed. If usage is not checked, write `Usage not checked`; if a checked usage tool returns no usages, write `None found`.

Great workspace-status output should feel like a small operations dashboard:

1. Start with a one-sentence health line, for example: `Deepnote workspace is reachable; the current MCP response includes 6 projects, 15 notebooks, 1 scheduled notebook, and 4 integrations.`
2. Add a compact `Key Signals` list with counts visible in the current MCP response for projects, notebooks, scheduled notebooks, recently run notebooks, failed or pending runs when checked, and integrations.
3. Use a Markdown project summary table as the main artifact, grouping notebooks by project.
4. Keep integrations inside the main table as an `Integrations` column for workspace summaries, notebook inventories, and project summaries.
5. Finish with `Notable Findings` only when there is something actionable, such as a scheduled notebook with no last run, a pending/failed run, a notebook that prints environment variables, or an integration with no checked usage.

Use this project summary table shape for workspace summaries, notebook inventories, and "which notebooks do I have?" style requests unless the user asks for a different format:

| Project | Notebooks | Scheduled | Last Run Seen | Integrations |
| --- | ---: | --- | --- | --- |
| `Project name` | `N` | `Yes` if any notebook in the project is scheduled, otherwise `No` | `YYYY-MM-DD HH:MM UTC`, `None seen`, or `Not visible via MCP` | `Integration name/Type, Integration name/Type` or `None found` |

For `Last Run Seen`, use the most recent visible `lastRunAt` across notebooks in the project, or a checked `get_run` completion time when more current. Format dates in UTC as `YYYY-MM-DD HH:MM UTC`. Do not write "None seen" when a run ID or run timestamp is visible.

For `Integrations`, use integration names and IDs from `list_integrations`, then map usage with `list_integration_project_usages`, `list_integration_notebook_usages`, or `list_integration_block_usages` when direct usage matters. You may also mention visible references from `get_notebook` blocks or `get_run` snapshot content. Do not infer usage from integration names alone; say `None found` only when checked usage or visible references return no connection.

Use this notebook-detail table only when the user asks for per-notebook detail, a specific project breakdown, or a specific notebook summary:

| Project | Notebook | Scheduled | Last Run Seen | Integrations |
| --- | --- | --- | --- | --- |
| `Project name` | `Notebook name` | `Yes` or `No` | `YYYY-MM-DD HH:MM UTC`, `None seen`, or `Not visible via MCP` | `Integration name/Type` or `None found` |

Use a standalone integration table only when the user explicitly asks for an integration inventory or integration usage report. In normal workspace and notebook summaries, do not split integrations into a separate table; keep them in the `Integrations` column.

| Integration | Type | Visible Notebook Usage |
| --- | --- | --- |
| `Integration name` | `type` | `Project / Notebook` from usage tools, `None found`, or `Usage not checked` |

Keep the table concise for large workspaces: include active notebooks, scheduled notebooks, and notebooks with visible linked connections first; then summarize any remaining notebooks by count.

Avoid calling notebooks "currently open" or "currently running" unless a current MCP tool exposes live session state. Prefer `recently run`, `scheduled`, `pending run`, or `last run`.

## Safety Rules

- Do not expose the bearer token or any secret values from integrations or notebook inputs. Refer to secret names only.
- Avoid downloading or printing large datasets. Sample, summarize, or aggregate data unless the user explicitly asks for an export.
- Treat notebook execution as potentially stateful and costly. The hosted MCP `create_run` tool starts a notebook run, not a single-cell edit or targeted cell run.
- Run input overrides apply to one run only. Do not claim they changed notebook defaults.
- If a tool returns `isError`, surface the user-facing error message concisely. For `create_run` failures such as workspace or parallel run limits, only call `get_run` if the `create_run` response includes a valid run ID; otherwise do not poll `get_run`.
- The hosted MCP toolset is mostly read/search/docs/usage mapping plus notebook execution. Do not claim to edit notebooks, projects, integrations, permissions, schedules, or publishing through the Deepnote MCP server unless such tools are exposed in the current session.

## Response Style

Keep responses grounded in Deepnote state: project name, notebook name, cell or block labels, execution status, and relevant links when the MCP server provides them. If a task cannot be completed through the Deepnote MCP server, explain the missing capability and offer the nearest safe next step.

Default to brief, concise, information-dense answers. Use tables, counts, status labels, and only the highest-signal findings. Do not include long explanations, raw snapshots, full block contents, or exhaustive notebook lists unless the user asks for more detail.
