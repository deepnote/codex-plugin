---
name: deepnote-links
description: Use when a task asks for Deepnote URLs, links, project links, notebook links, workspace links, share links, or when a Deepnote response should include clickable links built from MCP project, notebook, or workspace data.
---

# Deepnote Links

Use this skill to build user-facing Deepnote web links from MCP data. Prefer links grounded in `get_me`, `list_projects`, `search`, and `get_notebook` responses instead of guessing from names alone.

## Inputs To Resolve

1. Call `get_me` when workspace-aware links are useful. Use `workspace.id` and `workspace.slug`; do not use the API key name, bearer token, or user email in links or summaries.
2. Resolve the project with `list_projects` or `search`. Use the project `id`, `name`, and `slug` if the MCP response exposes one.
3. Resolve notebook links with `get_notebook` when possible. Use the notebook `id`, `name`, and parent project data.
4. If the exact project or notebook is ambiguous, ask a short clarification or provide a compact candidate list with links only for unambiguous matches.

## URL Shapes

Use the production web origin `https://deepnote.com` for Deepnote MCP links. Do not derive the web origin from API or MCP hosts.

Prefer workspace-scoped links when `get_me` returns both `workspace.slug` and `workspace.id`:

```text
workspaceSlugWithId = {workspace.slug}-{workspace.id}
workspace link = {origin}/workspace/{workspaceSlugWithId}
project link = {origin}/workspace/{workspaceSlugWithId}/project/{projectSegment}
notebook link = {origin}/workspace/{workspaceSlugWithId}/project/{projectSegment}/notebook/{notebookSegment}
```

If workspace data is not available, use the non-workspace project route:

```text
project link = {origin}/project/{projectSegment}
notebook link = {origin}/project/{projectSegment}/notebook/{notebookSegment}
```

## Slug Segments

Use the most canonical segment available:

1. If the MCP response exposes a `slug`, use it.
2. Otherwise, for simple names, build a readable segment as `{slugifiedName}-{id}`.
3. If exact slugification is uncertain, the name is missing, or the name has unusual characters, use the ID alone.

Deepnote project routing accepts UUID-only project segments, so `{project.id}` is the safest fallback. Notebook routing uses ID-only segments when a notebook name is not available, so `{notebook.id}` is the safest notebook fallback.

Deepnote's readable slugs are created with strict slugification: spaces become hyphens, `/` becomes `-`, unsafe characters are stripped or normalized, and case is preserved. Examples:

```text
Subject Tracker + 0508fc64-b2c8-4982-b6a0-2590c94b6000
=> Subject-Tracker-0508fc64-b2c8-4982-b6a0-2590c94b6000

folder/notebook 10% + a1b2c3d4
=> folder-notebook-10percent-a1b2c3d4
```

## Optional Suffixes

- File paths, when exposed and requested, append after the project segment as `/{encodeURIComponent(filePath)}`.
- Cell or block anchors append as `#anchor`.
- Do not add UTM parameters or tracking query parameters unless the user asks for campaign links.
- Only generate published app links such as `/app/{authorSlug}/{projectSegment}` or `/streamlit-apps/{streamlitAppId}` when MCP data explicitly exposes the published author slug or Streamlit app ID.

## Response Style

Return Markdown links with human-readable labels:

```markdown
[Project Name](https://deepnote.com/workspace/workspace-slug-workspace-id/project/project-id)
[Notebook Name](https://deepnote.com/workspace/workspace-slug-workspace-id/project/project-id/notebook/notebook-id)
```

For lists or inventories, put links in the `Project` or `Notebook` column and keep IDs in a separate column only when they help disambiguate. If a link cannot be built safely because workspace, project, or notebook data is missing, say which field is missing and how to resolve it.
