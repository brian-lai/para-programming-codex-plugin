#!/usr/bin/env bash
set -euo pipefail

fail=0

if grep -Eq '^### Command$' docs/phased-plan-example.md; then
  echo "FAIL phased plan example labels skill requests as commands"
  fail=1
else
  echo "PASS phased plan example uses skill request headings"
fi

if grep -Eq '^## Command Comparison$|\| Step \| Command \| Output \|' docs/phased-plans-quick-reference.md; then
  echo "FAIL quick reference labels skill requests as commands"
  fail=1
else
  echo "PASS quick reference uses skill request labels"
fi

bash_requests="$(awk '/^```bash$/ {inside=1; next} /^```$/ {inside=0; next} inside && /^para-[a-z-]+([[:space:]]|$)/ {print}' docs/phased-plan-example.md)"
if [ -n "$bash_requests" ]; then
  echo "FAIL canonical skill requests appear in bash fences"
  echo "$bash_requests"
  fail=1
else
  echo "PASS canonical skill requests are not shell commands"
fi

exit "$fail"
