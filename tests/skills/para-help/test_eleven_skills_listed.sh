#!/usr/bin/env bash
set -euo pipefail
body=$(awk '/^---$/{c++; next} c>=2' skills/para-help/SKILL.md)
fail=0
for skill in para-init para-research para-plan para-review para-execute para-workflow para-summarize para-archive para-status para-check para-help; do
  if echo "$body" | grep -q -- "$skill"; then echo "PASS listed: $skill"; else echo "FAIL missing: $skill"; fail=1; fi
done
if echo "$body" | grep -Fq 'Do not infer the host from ~/.agents/skills'; then
  echo "PASS guarded client rendering"
else
  echo "FAIL missing guarded client rendering"
  fail=1
fi
if echo "$body" | grep -Fq 'Use the `para-plan` skill'; then
  echo "PASS natural-language fallback"
else
  echo "FAIL missing natural-language fallback"
  fail=1
fi
exit "$fail"
