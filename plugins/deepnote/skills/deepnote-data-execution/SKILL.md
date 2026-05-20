---
name: deepnote-data-execution
description: Use when running Deepnote notebooks, inspecting notebook inputs, reviewing integration references, or interpreting run status and snapshot outputs through the Deepnote MCP server.
---

# Deepnote Data And Execution

## Available Context

Use the Deepnote MCP server for the execution and context it currently exposes:

- `get_notebook` for notebook blocks, input variables, last-run metadata, and integration references visible in blocks.
- `list_integrations` for workspace integration names and types.
- `list_integration_project_usages`, `list_integration_notebook_usages`, and `list_integration_block_usages` for direct integration usage mapping.
- `create_run` to start full-notebook execution, optionally with input values.
- `get_run` for run status, errors, completion time, and run snapshots. When `snapshotDelivery` is omitted, it returns a short-lived `snapshotDownloadUrl` when a snapshot is available; this is equivalent to `snapshotDelivery: "downloadUrl"`. Request `snapshotDelivery: "inline"` only when you need `snapshotContent` in the tool response.
- `get_me` for the authenticated workspace, API key type, and caller access level when execution permissions or workspace identity matter.

Do not claim direct access to database schemas, table previews, file metadata, query previews, or environment configuration unless a current MCP tool explicitly exposes that data.

## Execution Workflow

1. Read the notebook context first with `get_notebook`.
2. Identify whether the user needs a fresh run or whether existing run metadata is enough.
3. If the notebook has inputs and the user supplied values, map values to the exact input `name` fields returned by `get_notebook`.
4. Check whether execution may mutate data, call external services, trigger schedules, or consume significant compute.
5. Use `create_run` only for full-notebook execution by `notebookId`; the hosted MCP server does not currently expose single-block execution.
6. If `create_run` returns an MCP error, report that error and stop; do not call `get_run` unless a run ID was returned.
7. Use `get_run` to inspect status, errors, completion time, and snapshot availability before reporting results. For routine status checks, omit `snapshotDelivery` so the default download URL delivery is used; request `snapshotDelivery: "inline"` when you need to inspect notebook outputs, snapshot errors, or result details.

Before starting a run, inspect the notebook for cells that print environment variables, secrets, credentials, or entire configuration objects. If found, warn the user and get explicit confirmation before running. Also warn before running notebooks that start servers, send bulk requests, call external services, or mutate data.

## Notebook Run Inputs

`create_run` accepts an optional `inputs` object. Keys must be notebook input names from `get_notebook`, not labels or block IDs. Values must match the input block type:

- Text, textarea, file, date, slider, and single-select inputs use strings.
- Checkbox inputs use booleans.
- Multi-select inputs use arrays of strings.
- Date-range inputs use a string or an array of exactly two strings.
- Slider values must be numeric strings.

If the user provides a label instead of a name, inspect `get_notebook` inputs and map it to the closest input `name` only when the match is unambiguous. Otherwise ask for clarification. Run input values apply only to the new run and do not update the notebook's saved defaults.

## Run Snapshots

When `snapshotDelivery` is omitted, `get_run` returns `snapshotDownloadUrl` for available `.snapshot.deepnote` files and `snapshotContent: null`; this is equivalent to `snapshotDelivery: "downloadUrl"`. The URL is short-lived and grants access to the run snapshot, so do not paste it into the final answer unless the user asks for a download link or file handoff.

Use `snapshotDelivery: "inline"` when the user asks you to inspect outputs, summarize results, diagnose a failed run from snapshot details, map visible references from the snapshot, or otherwise reason over the snapshot content. Inline snapshots can be large and sensitive, so summarize the relevant blocks, outputs, failures, or data shape instead of dumping raw content.

If the current MCP tool schema does not expose `snapshotDelivery`, use the fields returned by `get_run` as-is and do not invent `snapshotContent` or `snapshotDownloadUrl`.

## Sensitive Outputs

When snapshot content, snapshot download URLs, or errors include sensitive, proprietary, personal, or production-like data, minimize exposure in the response. Summarize the result, shape, quality issues, aggregates, or failure mode instead of dumping raw records, presigned URLs, or long logs.

## Environment Changes

The hosted Deepnote MCP server currently does not expose environment mutation tools. Do not claim to change package versions, environment images, hardware, integrations, credentials, secrets, scheduled runs, or shared app settings through MCP.

## Reporting Results

For successful runs, include the executed notebook name or ID, run ID, status, any input overrides that are safe to mention, and the important result from inline snapshot content when you requested it. If you only have `snapshotDownloadUrl`, mention that a snapshot is available without exposing the URL by default. For failures, include concise error detail and the next fix to try. If a run fails before it starts, such as a workspace or parallel run limit, report the user-facing API error directly. Avoid pasting long logs unless the user asks for them.

Keep run reports brief and information-dense unless the user asks for detail. Prefer one compact run table plus the most important result or first actionable error. Do not paste long logs, raw snapshots, or full notebook outputs by default.

Prefer this run summary shape:

| Field | Value |
| --- | --- |
| Notebook | `Notebook name` |
| Run ID | `run-id` |
| Status | `success`, `failed`, `pending`, or `running` |
| Started | `YYYY-MM-DD HH:MM UTC` |
| Completed | `YYYY-MM-DD HH:MM UTC` or `Still running` |
| Inputs | `safe input summary` or `None` |
| Result | `short result summary` |

For failed or stuck runs, use a debugging report:

| Check | Finding |
| --- | --- |
| Run state | `failed`, `pending`, or `running for N minutes` |
| First actionable error | `short error text` |
| Likely cause | `missing input`, `missing file`, `server not listening`, `dependency failure`, or `unknown from MCP` |
| Safe next step | `inspect notebook`, `rerun with inputs`, `start serving notebook`, or `manual Deepnote action needed` |

When inspecting a large run snapshot, request inline delivery only when necessary, then summarize block counts, failed blocks, final outputs, and the first actionable error instead of pasting the snapshot.
