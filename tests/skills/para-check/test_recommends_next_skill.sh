#!/usr/bin/env bash
set -euo pipefail
if grep -Fq 'Use the `para-plan` skill' skills/para-check/SKILL.md; then
  echo "PASS para-plan semantic handoff"
else
  echo "FAIL missing para-plan semantic handoff"
  exit 1
fi
