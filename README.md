# Deepnote Codex Plugin

Use Deepnote from Codex to search workspaces, inspect notebooks, list integrations, start notebook runs, and summarize run status and outputs.

## What Is Included

- Codex marketplace manifest in `.agents/plugins/marketplace.json`
- Deepnote plugin manifest in `plugins/deepnote/.codex-plugin/plugin.json`
- Hosted Deepnote MCP configuration in `plugins/deepnote/.mcp.json`
- Deepnote skills for workspace search, notebook inspection, and notebook execution workflows
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
- `list_projects`: list workspace projects, optionally filtered by name
- `list_integrations`: list workspace integrations, optionally filtered by name or type
- `get_notebook`: inspect notebook details, blocks, input variables, and last-run metadata
- `create_run`: start a full notebook run, optionally with input values
- `get_run`: inspect run status, errors, completion time, and snapshot content when available

The current hosted MCP toolset does not expose notebook editing, single-block execution, direct database schema browsing, environment mutation, permissions changes, publishing, or scheduling changes.

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
- `Inspect this Deepnote notebook and summarize its inputs.`
- `Run this Deepnote notebook with customer_name set to Acme.`
- `List Deepnote integrations matching Snowflake.`

## Troubleshooting

- If authentication fails, confirm `DEEPNOTE_MCP_TOKEN` is set in the environment Codex actually starts from.
- If a resource is missing, check that the API key creator has access to the workspace, project, notebook, or integration.
- If a notebook run with inputs fails before starting, check that each input key matches a `get_notebook` input `name` and that each value matches the input type.
- If a run fails, ask Codex to inspect the run with `get_run` and summarize the error.
- If Codex suggests an edit or environment change, remember that the current hosted MCP server is read/search plus full-notebook execution only.

## License

Apache-2.0. See [LICENSE](LICENSE).
