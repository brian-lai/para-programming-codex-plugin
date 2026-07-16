#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

output="$(HOME="$tmp_home" bash "$REPO_ROOT/scripts/install.sh")"

if echo "$output" | grep -Fq 'Use the para-init skill to initialize PARA in a project.' &&
   echo "$output" | grep -Fq 'Use /skills to browse installed skills.'; then
  echo "PASS install output uses portable para-init guidance"
else
  echo "FAIL install output missing portable para-init or /skills management guidance"
  exit 1
fi

for skill in para-init para-plan para-execute para-help; do
  if [ ! -f "$tmp_home/.agents/skills/$skill/SKILL.md" ]; then
    echo "FAIL missing installed user skill $skill"
    exit 1
  fi

  if [ ! -f "$tmp_home/.codex/skills/$skill/SKILL.md" ]; then
    echo "FAIL missing compatibility skill mirror $skill"
    exit 1
  fi
done

if [ ! -f "$tmp_home/.agents/docs/METHODOLOGY.md" ]; then
  echo "FAIL missing installed user methodology docs"
  exit 1
fi

if [ ! -f "$tmp_home/.codex/docs/METHODOLOGY.md" ]; then
  echo "FAIL missing compatibility methodology docs mirror"
  exit 1
fi

if [ ! -f "$tmp_home/.agents/skills/para-init/resources/AGENTS.md" ]; then
  echo "FAIL missing installed user para-init resources"
  exit 1
fi

if [ ! -f "$tmp_home/.codex/skills/para-init/resources/AGENTS.md" ]; then
  echo "FAIL missing compatibility para-init resources mirror"
  exit 1
fi

if ! jq -e '.plugins[] | select(.name == "para-programming")' "$tmp_home/.agents/plugins/marketplace.json" >/dev/null; then
  echo "FAIL missing marketplace registration"
  exit 1
fi

reinstall_output="$(HOME="$tmp_home" bash "$REPO_ROOT/scripts/install.sh")"
if echo "$reinstall_output" | grep -Fq 'Use the para-init skill to initialize PARA in a project.' &&
   echo "$reinstall_output" | grep -Fq 'Use /skills to browse installed skills.'; then
  echo "PASS idempotent install output preserves portable guidance"
else
  echo "FAIL idempotent install output missing portable guidance"
  exit 1
fi

echo "PASS install script installs Codex skills and support files"
