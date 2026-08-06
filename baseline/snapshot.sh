#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8080}"
base_url="${base_url%/}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
output_dir="${1:-$script_dir/http-snapshots}"
mkdir -p "$output_dir"

raw="$(mktemp)"
body="$(mktemp)"
staging_dir="$(mktemp -d)"
cleanup() {
  rm -f "$raw" "$body"
  rm -rf "$staging_dir"
}
trap cleanup EXIT

connection_failure=0
snapshots=(
  'root.http|/'
  'vets.html.http|/vets.html'
  'owners-lastName.http|/owners?lastName='
  'owners-1.http|/owners/1'
)

snapshot() {
  local name="$1"
  local path="$2"
  local status=""
  local redirects=""
  local effective_url=""
  local effective_path=""
  local curl_info=""
  local curl_exit=0

  : > "$body"
  if curl_info="$(curl -sS -L -o "$body" \
    --connect-timeout 10 --max-time 60 \
    -w '%{http_code}\t%{num_redirects}\t%{url_effective}' \
    "$base_url$path")"; then
    :
  else
    curl_exit=$?
  fi
  if ((curl_exit != 0)); then
    connection_failure=1
    printf 'snapshot: %s failed (curl exit %s)\n' "$path" "$curl_exit" >&2
    return
  fi
  IFS=$'\t' read -r status redirects effective_url <<< "$curl_info"
  if [[ ! "$status" =~ ^[1-5][0-9]{2}$ ]]; then
    connection_failure=1
    printf 'snapshot: %s unavailable (HTTP status %s)\n' \
      "$path" "${status:-none}" >&2
    return
  fi
  effective_path="$(printf '%s\n' "$effective_url" | sed -E 's#^[^:]+://[^/]+(/.*)$#\1#')"
  if [[ "$effective_path" == "$effective_url" || -z "$effective_path" ]]; then
    effective_path="/"
  fi
  sed -E \
    -e 's/([?&;])jsessionid=[^"'\''< >?#;&]+/\1/gI' \
    -e 's/(name=["'\''"](_csrf|csrf)["'\''"][^>]*value=["'\''"])[^"'\''"]*/\1<CSRF>/gI' \
    -e 's/(name=["'\''"](_csrf|csrf)["'\''"][^>]*value=)[^"'\''< >]+/\1<CSRF>/gI' \
    -e 's/(name=(_csrf|csrf)[^>]*value=["'\''"])[^"'\''"]*/\1<CSRF>/gI' \
    -e 's/(name=(_csrf|csrf)[^>]*value=)[^"'\''< >]+/\1<CSRF>/gI' \
    -e 's/(value=["'\''"])[^"'\''"]*(["'\''"][^>]*name=["'\''"](_csrf|csrf)["'\''"])/\1<CSRF>\2/gI' \
    "$body" > "$raw"
  {
    printf 'HTTP status: %s\nHTTP redirects: %s\nEffective path: %s\n\n' \
      "$status" "$redirects" "$effective_path"
    cat "$raw"
  } > "$staging_dir/$name"
}

for entry in "${snapshots[@]}"; do
  IFS='|' read -r name path <<< "$entry"
  snapshot "$name" "$path"
done

if ((connection_failure)); then
  exit 1
fi

# Publish only after all captures succeed; every staging file must exist.
for entry in "${snapshots[@]}"; do
  name="${entry%%|*}"
  mv "$staging_dir/$name" "$output_dir/$name"
done
