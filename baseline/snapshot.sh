#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8080}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
output_dir="${1:-$script_dir/http-snapshots}"
mkdir -p "$output_dir"

raw="$(mktemp)"
body="$(mktemp)"
cleanup() {
  rm -f "$raw" "$body"
}
trap cleanup EXIT

snapshot() {
  local name="$1"
  local path="$2"
  local status

  if status="$(curl -sS -L -o "$body" -w '%{http_code}' \
    "$base_url$path")"; then
    :
  else
    status="${status:-000}"
  fi
  sed -E \
    -e 's/([?&;])jsessionid=[^"'\''< >?#;]+/\1/gI' \
    -e 's/(name=["'\''"](_csrf|csrf)["'\''"][^>]*value=["'\''"])[^"'\''"]*/\1<CSRF>/gI' \
    -e 's/(name=(_csrf|csrf)[^>]*value=["'\''"])[^"'\''"]*/\1<CSRF>/gI' \
    -e 's/(name=(_csrf|csrf)[^>]*value=)[^"'\''< >]*/\1<CSRF>/gI' \
    -e 's/(value=["'\''"])[^"'\''"]*(["'\''"][^>]*name=["'\''"](_csrf|csrf)["'\''"])/\1<CSRF>\2/gI' \
    -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9:.+-]+)?/<DATE>/g' \
    -e 's/[0-9]{2}\/[0-9]{2}\/[0-9]{4}/<DATE>/g' \
    "$body" > "$raw"
  {
    printf 'HTTP status: %s\n\n' "$status"
    cat "$raw"
  } > "$output_dir/$name"
}

snapshot "root.http" "/"
snapshot "vets.html.http" "/vets.html"
snapshot "owners-lastName.http" "/owners?lastName="
snapshot "owners-1.http" "/owners/1"
