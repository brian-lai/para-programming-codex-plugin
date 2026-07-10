#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPEC="$REPO_ROOT/tests/conformance/spec.yaml"
fail=0

pass() { echo "PASS $1"; }
fail_test() { echo "FAIL $1"; fail=1; }

canonical="$(yq -r '.invocation_contract.canonical_request.display_pattern' "$SPEC")"
if [ "$canonical" = 'para-<skill> [arguments]' ] &&
   ! yq -r '.cross_skill_references.cross_skill_invocations[].invokes[]' "$SPEC" | grep -Eq '^(\$|/)'; then
  pass "canonical request is bare"
else
  fail_test "canonical request is not bare"
fi

names="$(yq -r '.skills_to_deliver[]' "$SPEC" | paste -sd'|' -)"
concrete="(${names})"
dollar='\$'
selector_forms="(${dollar}${concrete}|/${concrete}|/skill:${concrete}|${dollar}para-<skill>|/para-<name>|/skill:para-<skill>|${dollar}para-\*|${dollar}para-command)"
selector_regex="(^|[^[:alnum:]_./:-])${selector_forms}($|[^[:alnum:]_./-])"

fixtures_ok=1
while IFS= read -r fixture; do
  if ! printf '%s\n' "$fixture" | grep -Eq "$selector_regex"; then
    echo "FAIL selector lexer missed positive fixture: $fixture"
    fixtures_ok=0
  fi
done < <(yq -r '.invocation_contract.selector_lexer.positive_fixtures[]' "$SPEC")

while IFS= read -r fixture; do
  if printf '%s\n' "$fixture" | grep -Eq "$selector_regex"; then
    echo "FAIL selector lexer matched negative fixture: $fixture"
    fixtures_ok=0
  fi
done < <(yq -r '.invocation_contract.selector_lexer.negative_fixtures[]' "$SPEC")

if [ "$fixtures_ok" -eq 1 ]; then
  pass "selector lexer fixtures"
else
  fail=1
fi

scan_file() {
  local file="$1"
  if grep -En "$selector_regex" "$file" >/dev/null; then
    echo "FAIL invocation selector token in portable file: ${file#"$REPO_ROOT"/}"
    grep -En "$selector_regex" "$file" || true
    return 1
  fi
}

scan_scope() {
  local scope="$1" pattern file scope_fail=0 matched
  while IFS= read -r pattern; do
    matched=0
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      matched=1
      scan_file "$file" || scope_fail=1
    done < <(compgen -G "$REPO_ROOT/$pattern" || true)
    if [ "$matched" -eq 0 ]; then
      fail_test "portable scope pattern matched no files: $pattern"
      scope_fail=1
    fi
  done < <(yq -r ".invocation_contract.portable_scopes.${scope}.paths[]" "$SPEC")
  return "$scope_fail"
}

if scan_scope skill; then
  pass "portable skill selector token scan"
else
  fail=1
fi

if scan_scope documentation; then
  pass "portable documentation selector token scan"
else
  fail=1
fi

start="$(yq -r '.invocation_contract.mapping_surfaces.block_start' "$SPEC")"
end="$(yq -r '.invocation_contract.mapping_surfaces.block_end' "$SPEC")"
mapping_ok=1
while IFS= read -r rel; do
  file="$REPO_ROOT/$rel"
  start_count="$(grep -Fxc "$start" "$file" || true)"
  end_count="$(grep -Fxc "$end" "$file" || true)"
  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    echo "FAIL $rel must contain exactly one invocation mapping block"
    mapping_ok=0
    continue
  fi

  block="$(awk -v start="$start" -v end="$end" '$0 == start {inside=1; next} $0 == end {inside=0; exit} inside' "$file")"
  outside="$(awk -v start="$start" -v end="$end" '$0 == start {inside=1; next} $0 == end {inside=0; next} !inside' "$file")"

  while IFS=$'\t' read -r client label value_client value_field; do
    expected="$(yq -r ".invocation_contract.rendering_policy.clients[\"${value_client}\"].${value_field}" "$SPEC")"
    row_count="$(printf '%s\n' "$block" | awk -F'|' -v label="$label" '{cell=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell); if (cell == label) count++} END {print count+0}')"
    row_value="$(printf '%s\n' "$block" | awk -F'|' -v label="$label" '{cell=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell); if (cell == label) {value=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); print value}}')"
    if [ "$row_count" -ne 1 ] || ! printf '%s\n' "$row_value" | grep -Fq "$expected"; then
      echo "FAIL $rel mapping row $label does not match $client value: $expected"
      mapping_ok=0
    fi
  done < <(yq -r '.invocation_contract.mapping_surfaces.rows[] | [.client, .label, .value_client, .value_field] | @tsv' "$SPEC")

  if printf '%s\n' "$outside" | grep -Eq "$selector_regex"; then
    echo "FAIL $rel contains PARA invocation selector outside mapping block"
    mapping_ok=0
  fi
done < <(yq -r '.invocation_contract.mapping_surfaces.paths[]' "$SPEC")

if [ "$mapping_ok" -eq 1 ]; then
  pass "mapping blocks match spec"
else
  fail=1
fi

if [ "$(yq -r '.invocation_contract.rendering_policy.clients.opencode.user_form' "$SPEC")" = "natural-language" ] &&
   [ "$(yq -r '.invocation_contract.rendering_policy.clients.opencode.expose_agent_tool_syntax_to_user' "$SPEC")" = "false" ] &&
   [ "$(yq -r '.invocation_contract.rendering_policy.clients."gemini-cli".user_form' "$SPEC")" = "natural-language" ] &&
   [ "$(yq -r '.invocation_contract.rendering_policy.clients."gemini-cli".expose_agent_tool_syntax_to_user' "$SPEC")" = "false" ]; then
  pass "agent-tool clients use natural language"
else
  fail_test "agent-tool clients expose internal activation syntax"
fi

if [ "$(yq -r '.invocation_contract.rendering_policy.clients.unknown.user_form' "$SPEC")" = "natural-language" ] &&
   grep -Fq 'Do not infer the host from ~/.agents/skills' "$REPO_ROOT/skills/para-help/SKILL.md"; then
  pass "unknown-client fallback"
else
  fail_test "unknown-client fallback is missing"
fi

management_ok=1
for rel in README.md INSTALL.md; do
  if ! grep -Fq 'Management and discovery' "$REPO_ROOT/$rel"; then
    echo "FAIL $rel does not separate management and discovery"
    management_ok=0
  fi
done
if [ "$management_ok" -eq 1 ]; then
  pass "management is separate from invocation"
else
  fail=1
fi

exit "$fail"
