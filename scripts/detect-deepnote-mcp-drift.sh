#!/bin/bash -e

if [ -z "${DEEPNOTE_TOKEN}" ]; then
  echo "DEEPNOTE_TOKEN is not set"
  exit 1
fi

curl -sS https://deepnote.com/mcp \
  -X POST \
  -H "Authorization: Bearer ${DEEPNOTE_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  | jq -r '.result.tools[].name' \
  | xargs -I{} sh -c 'grep -RqlF "$1" plugins/deepnote && echo "ok  $2" || { echo "MISSING  $2"; exit 1; }' _ '`{}`' '{}'
