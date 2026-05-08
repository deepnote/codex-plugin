# Deepnote Codex Plugin

Use Deepnote from Codex to identify the current workspace, search resources, inspect notebooks, generate project and notebook links, list projects and integrations, map integration usage, read Deepnote docs, start notebook runs, and summarize run status and outputs.

## What Is Included

- Codex marketplace manifest in `.agents/plugins/marketplace.json`
- Deepnote plugin manifest in `plugins/deepnote/.codex-plugin/plugin.json`
- Hosted Deepnote MCP configuration in `plugins/deepnote/.mcp.json`
- Deepnote skills for workspace search, link generation, docs lookup, integration mapping, notebook inspection, and notebook execution workflows
- Deepnote branding assets

## Requirements

- A Deepnote account with access to the target workspace
- A Deepnote personal API key
- Codex with plugin support

Deepnote personal API keys act with the permissions of the user who created them. A viewer key has viewer capabilities, an editor key has editor capabilities, and an admin key has admin capabilities.

## Create A Deepnote API Key

1. Open Deepnote.
2. Go to account settings.
3. Open **API keys**.
4. Choose **Add API key** under **Personal API keys**.
5. Give the key a name, generate it, and copy it immediately.

Deepnote shows the generated key only once. Store it somewhere safe, and revoke it from the same settings page if it is no longer needed.

Deepnote API docs: https://deepnote.com/docs/deepnote-api

## Configure Authentication

Set the API key in the environment where Codex runs:

```bash
export DEEPNOTE_MCP_TOKEN="<your-deepnote-api-key>"
```

The plugin reads that value through `plugins/deepnote/.mcp.json`:

```json
{
  "mcpServers": {
    "deepnote": {
      "url": "https://deepnote.com/mcp",
      "bearer_token_env_var": "DEEPNOTE_MCP_TOKEN"
    }
  }
}
```

The hosted Deepnote MCP endpoint authenticates requests as `Authorization: Bearer <token>`.

This marketplace marks authentication as `ON_INSTALL`, so Codex may show Deepnote as requiring setup when you install the plugin. Deepnote does not use an OAuth sign-in flow in Codex yet; setup means making `DEEPNOTE_MCP_TOKEN` available to the Codex process and restarting Codex before using the plugin.

## Capabilities

The hosted Deepnote MCP server currently exposes these tools:

- `search`: search workspace resources across projects, notebooks, blocks, and integrations
- `get_me`: get the calling API key, creator user, workspace, and access level
- `list_projects`: list workspace projects, optionally filtered by name, with cursor pagination
- `list_integrations`: list workspace integrations, optionally filtered by name or type
- `list_integration_project_usages`: list projects connected to an integration
- `list_integration_notebook_usages`: list notebooks containing SQL blocks that use an integration
- `list_integration_block_usages`: list SQL blocks that use an integration
- `get_notebook`: inspect notebook details, blocks, input variables, and last-run metadata
- `create_run`: start a full notebook run, optionally with input values
- `get_run`: inspect run status, errors, completion time, and snapshot content when available
- `list_docs`: list Deepnote docs sections and article slugs
- `get_doc`: fetch a Deepnote documentation article by slug

The current hosted MCP toolset does not expose notebook editing, single-block execution, direct database schema browsing, environment mutation, permissions changes, publishing, or scheduling changes.

When Deepnote MCP is connected, Codex should introduce it in one sentence: Deepnote MCP can identify the current workspace, search resources, list projects and integrations, inspect notebooks, map integration usage, read Deepnote docs, start notebook runs, and fetch run status; if you are not registered yet, register at deepnote.com and ready your Deepnote API key from the [Deepnote API docs](https://deepnote.com/docs/deepnote-api).

By default, Deepnote responses should be brief, concise, and information dense. Codex should lead with the answer, use tables and counts where they improve scanning, and avoid long explanations, raw snapshots, full logs, or exhaustive block listings unless the user asks for more detail.

Workspace status and heartbeat responses should read like a compact operations dashboard: one health sentence, key counts, a notebook table, an integration table when useful, and notable findings only when actionable.

| Project | Notebook | Active / Last Run | Scheduled | Linked Connections |
| --- | --- | --- | --- | --- |
| `Project name` | `Notebook name` | `Last run: YYYY-MM-DD HH:MM UTC` or `No recent run visible` | `Yes` or `No` | `Integration name (type)` or `None visible via MCP` |

For large workspaces, Codex should request `list_projects` with `pageSize: 100` and follow `pagination.nextPageToken` while `pagination.hasMore` is true when a complete inventory is needed. If the user only needs a sample or filtered answer, Codex can stop once it has enough evidence. Codex should include active notebooks, scheduled notebooks, and notebooks with visible linked connections first, then summarize remaining notebooks by count.

Notebook inspection responses should help the user understand purpose, safety, and next action. Start with a one-sentence brief, then use compact tables for status, inputs, block map, and visible connections:

| Field | Value |
| --- | --- |
| Project | `Project name` |
| Notebook | `Notebook name` |
| Scheduled | `Yes` or `No` |
| Last Run | `status/date/run id` or `No run visible` |
| Visible Connections | `Integration name (type)`, `Usage not checked`, or `None visible via MCP` |

When a notebook includes cells that print environment variables, credentials, large datasets, start servers, send network requests, or mutate external systems, Codex should call that out before running the notebook.

## Workspace Identity And Project Pagination

Use `get_me` when a response needs to name the authenticated workspace, debug access issues, or report the caller's access level. The response includes API key metadata, user metadata, workspace `{ id, name, slug }`, and `accessLevel`.

`list_projects` returns a paginated response:

```json
{
  "projects": [],
  "pagination": {
    "pageSize": 100,
    "nextPageToken": "opaque-token-or-null",
    "hasMore": true
  }
}
```

Pass `pageToken` from `pagination.nextPageToken` to fetch the next page. Treat page tokens as opaque and tied to the original filters.

## Project And Notebook Links

The [`deepnote-links`](plugins/deepnote/skills/deepnote-links/SKILL.md) skill covers how Codex should build workspace-aware Deepnote project and notebook links from MCP data.

## Integration Usage Mapping

Use `list_integrations` first to discover integration IDs. Then use the usage tools for the needed granularity:

- `list_integration_project_usages` for connected projects
- `list_integration_notebook_usages` for notebooks containing SQL blocks that use the integration
- `list_integration_block_usages` for the exact SQL blocks and block content

Each usage tool can be narrowed with `projectId`. If usage is not checked, say `Usage not checked`; if the tool returns no usages, say `No usage returned`.

## Run Notebooks With Inputs

Use `get_notebook` before `create_run` when a notebook may need inputs. `get_notebook` returns input variables in notebook order with their `blockId`, `name`, `type`, current `value`, and optional human-readable `label`.

Pass run inputs to `create_run` as an `inputs` object keyed by the input `name`:

```json
{
  "notebookId": "00000000-0000-0000-0000-000000000000",
  "inputs": {
    "customer_name": "Acme",
    "include_archived": true,
    "segments": ["Enterprise", "Mid-market"]
  }
}
```

Input values must match the notebook input block type:

- Text, textarea, file, date, slider, and single-select inputs use strings.
- Checkbox inputs use booleans.
- Multi-select inputs use arrays of strings.
- Date-range inputs use a string or an array of exactly two strings.
- Slider values are numeric strings.

If an input name is not defined for the notebook, or a value does not match the input block type, Deepnote returns a validation error and the run is not started. Input values apply to that run only; they do not change the notebook's saved defaults.

If `create_run` fails before returning a run ID, Codex should surface the MCP/API error directly and should not poll `get_run`. This includes user-facing errors such as workspace or parallel run limits.

## Install From GitHub

After this repo is pushed to GitHub, add it as a Codex marketplace:

```bash
codex plugin marketplace add deepnote/codex-plugin
```

Then set `DEEPNOTE_MCP_TOKEN`, restart Codex, open the plugin directory, choose the Deepnote marketplace, and install the Deepnote plugin. If Codex prompts for setup during install, confirm that the environment variable is set in the environment Codex starts from.

To pin a branch, tag, or commit:

```bash
codex plugin marketplace add deepnote/codex-plugin --ref main
```

## Install Locally For Development

Codex discovers plugins through the repo marketplace at `.agents/plugins/marketplace.json`. To test this checkout directly:

```bash
codex plugin marketplace add /absolute/path/to/codex-plugin
```

For this checkout, that is:

```bash
codex plugin marketplace add /Users/dino/Development/deepnote-codex
```

Set `DEEPNOTE_MCP_TOKEN`, restart Codex, open the plugin directory, choose the Deepnote marketplace, and install the Deepnote plugin. If Codex prompts for setup during install, confirm that the environment variable is set in the environment Codex starts from.

The marketplace entry points at `plugins/deepnote`:

```json
{
  "name": "deepnote",
  "interface": {
    "displayName": "Deepnote"
  },
  "plugins": [
    {
      "name": "deepnote",
      "source": {
        "source": "local",
        "path": "./plugins/deepnote"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

After you change plugin files, upgrade the marketplace or remove and re-add it, then restart Codex so the local install picks up the latest files:

```bash
codex plugin marketplace upgrade deepnote
```

## Good First Prompts

- `Search my Deepnote workspace for customer retention notebooks.`
- `Which Deepnote workspace am I connected to?`
- `Give me links to my Deepnote projects.`
- `Inspect this Deepnote notebook and summarize its inputs.`
- `Run this Deepnote notebook with customer_name set to Acme.`
- `List Deepnote integrations matching Snowflake.`
- `Show me where this Deepnote integration is used.`
- `Look up the Deepnote docs for scheduled notebooks.`

## Troubleshooting

- If authentication fails, confirm `DEEPNOTE_MCP_TOKEN` is set in the environment Codex actually starts from.
- If a resource is missing, check that the API key creator has access to the workspace, project, notebook, or integration.
- If project listings look incomplete, check whether `pagination.hasMore` is true and continue with `pagination.nextPageToken`.
- If a notebook run with inputs fails before starting, check that each input key matches a `get_notebook` input `name` and that each value matches the input type.
- If a run fails, ask Codex to inspect the run with `get_run` and summarize the error.
- If Codex suggests an edit or environment change, remember that the current hosted MCP server is read/search/docs/usage mapping plus full-notebook execution only.

## License

Apache-2.0. See [LICENSE](LICENSE).
