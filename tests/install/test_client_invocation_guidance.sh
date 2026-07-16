#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

for rel in README.md INSTALL.md; do
  file="$REPO_ROOT/$rel"
  for client in "OpenAI Codex" "Cursor" "Pi" "OpenCode" "Gemini"; do
    if grep -Fq "$client" "$file"; then
      echo "PASS $rel documents $client invocation"
    else
      echo "FAIL $rel missing $client invocation"
      fail=1
    fi
  done

  if grep -Fq '<!-- para-client-invocation-map:start -->' "$file" &&
     grep -Fq '<!-- para-client-invocation-map:end -->' "$file" &&
     grep -Fq 'natural-language' "$file"; then
    echo "PASS $rel documents invocation mapping and fallback"
  else
    echo "FAIL $rel missing invocation mapping or fallback"
    fail=1
  fi

  if grep -Fq 'Management and discovery' "$file"; then
    echo "PASS $rel separates management from invocation"
  else
    echo "FAIL $rel does not separate management from invocation"
    fail=1
  fi
done

exit "$fail"
