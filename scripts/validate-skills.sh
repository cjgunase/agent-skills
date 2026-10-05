#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill_count=0

while IFS= read -r skill_file; do
  skill_count=$((skill_count + 1))
  first_line=$(sed -n '1p' "$skill_file")
  [ "$first_line" = "---" ] || { echo "Missing YAML frontmatter: $skill_file" >&2; exit 1; }
  rg -q '^name: ' "$skill_file" || { echo "Missing name: $skill_file" >&2; exit 1; }
  rg -q '^description: ".+"$' "$skill_file" || { echo "Description must be quoted: $skill_file" >&2; exit 1; }
  if rg -n '(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|[0-9]{12}\.dkr\.ecr|/home/[^/]+)' "$(dirname "$skill_file")"; then
    echo "Potential private data in $(dirname "$skill_file")" >&2
    exit 1
  fi
  echo "Validated: ${skill_file#$repo_root/}"
done < <(find "$repo_root/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)

[ "$skill_count" -gt 0 ] || { echo "No skills found" >&2; exit 1; }
echo "Validated $skill_count skill(s)."
