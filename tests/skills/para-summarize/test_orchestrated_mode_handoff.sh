#!/usr/bin/env bash
set -euo pipefail
body=$(awk '/^---$/{c++; next} c>=2' skills/para-summarize/SKILL.md)
if echo "$body" | grep -q 'invoked as Step 4 of the `para-workflow` skill' && echo "$body" | grep -qi 'skip.*PR'; then
  echo "PASS para-workflow semantic handoff"
else
  echo "FAIL missing para-workflow semantic handoff"
  exit 1
fi
