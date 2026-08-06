#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:8080}"
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

snapshot() {
  local name="$1"
  local path="$2"
  local status
  local redirects
  local effective_url
  local effective_path
  local curl_info

  : > "$body"
  curl_info="$(curl -sS -L -o "$body" \
    -w '%{http_code}\t%{num_redirects}\t%{url_effective}' \
    "$base_url$path")" || true
  IFS=$'\t' read -r status redirects effective_url <<< "$curl_info"
  if [[ "$status" == "000" ]]; then
    connection_failure=1
    printf 'snapshot: %s unavailable (HTTP status 000)\n' "$path" >&2
    return
  fi
  effective_path="$(printf '%s\n' "$effective_url" | sed -E 's#^[^:]+://[^/]+(/.*)$#\1#')"
  sed -E \
    -e 's/([?&;])jsessionid=[^"'\''< >?#;]+/\1/gI' \
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

snapshot "root.http" "/"
snapshot "vets.html.http" "/vets.html"
snapshot "owners-lastName.http" "/owners?lastName="
snapshot "owners-1.http" "/owners/1"

if ((connection_failure)); then
  exit 1
fi

for name in root.http vets.html.http owners-lastName.http owners-1.http; do
  mv "$staging_dir/$name" "$output_dir/$name"
done
