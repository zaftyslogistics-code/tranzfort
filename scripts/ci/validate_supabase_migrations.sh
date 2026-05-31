#!/usr/bin/env bash
# P0-10: CI guard for Supabase migration naming and ordering (no DB required).
set -euo pipefail

MIG_DIR="${1:-supabase/migrations}"
if [[ ! -d "$MIG_DIR" ]]; then
  echo "Missing migrations directory: $MIG_DIR" >&2
  exit 1
fi

declare -a timestamps=()
errors=0

shopt -s nullglob
for file in "$MIG_DIR"/*.sql; do
  base="$(basename "$file")"
  if [[ "$base" == *.archived* ]] || [[ "$base" == MANUAL_* ]]; then
    continue
  fi
  if [[ ! "$base" =~ ^[0-9]{14}_[a-z0-9_]+\.sql$ ]]; then
    echo "ERROR: invalid migration filename: $base (expected YYYYMMDDHHMMSS_snake_case.sql)" >&2
    errors=$((errors + 1))
    continue
  fi
  ts="${base:0:14}"
  timestamps+=("$ts")
done

if [[ "${#timestamps[@]}" -eq 0 ]]; then
  echo "ERROR: no active migrations found in $MIG_DIR" >&2
  exit 1
fi

IFS=$'\n' sorted=($(printf '%s\n' "${timestamps[@]}" | sort))
unset IFS

prev=""
for ts in "${sorted[@]}"; do
  if [[ -n "$prev" && "$ts" == "$prev" ]]; then
    echo "ERROR: duplicate migration timestamp: $ts" >&2
    errors=$((errors + 1))
  fi
  if [[ -n "$prev" && "$ts" < "$prev" ]]; then
    echo "ERROR: migrations not in chronological order near $ts" >&2
    errors=$((errors + 1))
  fi
  prev="$ts"
done

if [[ "$errors" -gt 0 ]]; then
  echo "Migration validation failed with $errors error(s)." >&2
  exit 1
fi

echo "OK: ${#timestamps[@]} migrations validated in $MIG_DIR"
