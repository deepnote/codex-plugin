---
name: deepnote-utm-links
description: Use whenever generating Deepnote project or notebook links from MCP data so the links always include Codex/OpenAI MCP UTM attribution, including campaign links, tracking links, and clickable workspace summary links.
---

# Deepnote UTM Links

## Overview

Always add Codex/OpenAI MCP campaign attribution to user-facing Deepnote project and notebook links after the canonical Deepnote path has been built with `deepnote-links`.

## UTM Template

Use this query parameter set for every Deepnote project and notebook link:

```text
https://deepnote.com/<path>?utm_source=codex&utm_medium=mcp&utm_campaign=openaimcp&utm_content={notebook_id}&utm_term={tool_name}
```

Use these values exactly; braces mark placeholders and are not part of the final URL:

- `utm_source=codex`
- `utm_medium=mcp`
- `utm_campaign=openaimcp`
- `utm_content={notebook_id}`
- `utm_term={tool_name}`

For notebook links, set `utm_content` to the notebook ID. For project-only links, set `utm_content` to the project ID; when a project link represents a specific notebook's parent project, use that notebook ID instead.

Set `utm_term` to the MCP tool or workflow that produced or grounded the link, such as `list_projects`, `search`, `get_notebook`, or `workspace_summary`. Use lowercase snake_case tool names and URL-encode the value if needed.

## Applying Parameters

1. Build the canonical Deepnote URL first with `deepnote-links`.
2. Add the UTM parameters to project and notebook links before any URL fragment.
3. Use `?` when the URL has no existing query string, otherwise use `&`.
4. Preserve non-UTM query parameters if they already exist.
5. Replace any existing `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, or `utm_term` values instead of duplicating them.
6. Do not put UTM parameters in the visible link label; only add them to the URL target.

## Examples

Notebook link:

```markdown
[Notebook Name](https://deepnote.com/workspace/acme-ws-123/project/project-id/notebook/notebook-id?utm_source=codex&utm_medium=mcp&utm_campaign=openaimcp&utm_content=notebook-id&utm_term=get_notebook)
```

Project link:

```markdown
[Project Name](https://deepnote.com/workspace/acme-ws-123/project/project-id?utm_source=codex&utm_medium=mcp&utm_campaign=openaimcp&utm_content=project-id&utm_term=list_projects)
```
