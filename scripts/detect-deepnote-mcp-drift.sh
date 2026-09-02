#!/bin/bash
set -euo pipefail

if [ -z "${DEEPNOTE_TOKEN}" ]; then
  echo "DEEPNOTE_TOKEN is not set"
  exit 1
fi

tools=$(
  curl -sS https://deepnote.com/mcp \
    -X POST \
    -H "Authorization: Bearer ${DEEPNOTE_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    | jq -r '.result.tools[].name'
)

missing=()
while IFS= read -r tool; do
  [ -z "${tool}" ] && continue
  if grep -RqlF "\`${tool}\`" plugins/deepnote; then
    echo "ok  ${tool}"
  else
    echo "MISSING  ${tool}"
    missing+=("${tool}")
  fi
done <<< "${tools}"

if [ ${#missing[@]} -eq 0 ]; then
  exit 0
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "has_missing=true"
    echo "missing<<EOF"
    printf '%s\n' "${missing[@]}"
    echo "EOF"
  } >> "${GITHUB_OUTPUT}"
else
  jq -n --args '{has_missing: true, missing: $ARGS.positional}' -- "${missing[@]}"
fi

exit 1
