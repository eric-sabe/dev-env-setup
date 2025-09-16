#!/usr/bin/env bash
# Drift check stub: compares baseline/archives.json against current manifest archives entries.
# Reports:
#  - missing_in_manifest: baseline entry not present now
#  - new_in_manifest: manifest entry absent in baseline
#  - size_change: content_length differs (hash same)
#  - hash_change: sha256 differs
# Exit codes: 0 (no drift), 1 (drift detected)
# Usage: scripts/security/drift-check.sh [--baseline baseline/archives.json]

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
BASELINE="$ROOT_DIR/baseline/archives.json"
OUTPUT_JSON=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --baseline) BASELINE="$2"; shift 2;;
    --output-json) OUTPUT_JSON="$2"; shift 2;;
    -h|--help) echo "Usage: $0 [--baseline file] [--output-json file]"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $MANIFEST ]] || { echo "Missing manifest $MANIFEST" >&2; exit 2; }
[[ -f $BASELINE ]] || { echo "Missing baseline $BASELINE" >&2; exit 2; }

# Build maps
# baseline json structure expected: [{"name":"..","sha256":"..","content_length":123}, ...]
# We'll parse with awk/jq fallback. Prefer jq if present.

parse_baseline(){
  if command -v jq >/dev/null 2>&1; then
    jq -r '.[] | [.name,.sha256,(.content_length|tostring)] | @tsv' "$BASELINE"
  else
    # crude parser (expects simple flat objects per line or array) - recommend jq
    grep '"name"' -A3 "$BASELINE" | sed -n 's/.*"name" *: *"\([^"]*\)".*/NAME:\1/p; s/.*"sha256" *: *"\([^"]*\)".*/SHA:\1/p; s/.*"content_length" *: *\([0-9][0-9]*\).*/LEN:\1/p' | awk 'BEGIN{n="";s="";l=""} /^NAME:/{n=substr($0,6)} /^SHA:/{s=substr($0,5)} /^LEN:/{l=substr($0,5); if(n&&s){print n"\t"s"\t"l; n="";s="";l=""}}'
  fi
}

# Extract manifest archives lines to tsv name sha len
parse_manifest(){
  awk 'BEGIN{inA=0;name="";sha="";len=""}
    /^archives:/ {inA=1;next}
    inA==0 {next}
    /^gpg_keys:/ {inA=0; next}
    /^ *- name:/ {
      # emit previous pending item if somehow sha missing (skip if empty)
      if(name && sha){print name"\t"sha"\t"len}
      name=$0; sub(/.*- name:[[:space:]]*/ ,"",name); sha=""; len=""; next
    }
    /content_length:/ { if(name){len=$2} }
    /sha256:/ { if(name){sha=$2} }
    # end of file will flush via END
    END{ if(name && sha){print name"\t"sha"\t"len} }
  ' "$MANIFEST"
}

BASE_NAMES=(); BASE_SHAS=(); BASE_LENS=()
while IFS=$'\t' read -r n s l; do
  BASE_NAMES+=("$n"); BASE_SHAS+=("$s"); BASE_LENS+=("$l")
done < <(parse_baseline)

find_in_base(){
  local target="$1"; local idx=0
  for name in "${BASE_NAMES[@]}"; do
    if [[ $name == "$target" ]]; then
      echo $idx; return 0
    fi
    idx=$((idx+1))
  done
  return 1
}

DRIFT=0
report_line(){ printf '%s\n' "$1"; }
USED_IDX=()

while IFS=$'\t' read -r n s l; do
  if ! idx=$(find_in_base "$n"); then
    report_line "new_in_manifest $n"; DRIFT=1; continue
  fi
  USED_IDX+=("$idx")
  bsha="${BASE_SHAS[$idx]}"; blen="${BASE_LENS[$idx]}"
  if [[ $bsha != "$s" ]]; then
    report_line "hash_change $n baseline=$bsha current=$s"; DRIFT=1
  else
    if [[ -n $blen && -n $l && $blen != "$l" ]]; then
      report_line "size_change $n baseline=$blen current=$l"; DRIFT=1
    fi
  fi
done < <(parse_manifest)

# Missing (in baseline but not manifest)
for i in "${!BASE_NAMES[@]}"; do
  skip=0
  if [[ ${#USED_IDX[@]:-0} -gt 0 ]]; then
    for used in "${USED_IDX[@]}"; do [[ $used == "$i" ]] && { skip=1; break; }; done
  fi
  (( skip )) && continue
  report_line "missing_in_manifest ${BASE_NAMES[$i]}"; DRIFT=1
done

if [[ -n $OUTPUT_JSON ]]; then
  # simple JSON construction
  mapfile -t lines < <( { parse_manifest | awk '{print "manifest_entry " $0}' ; } )
  # Not exporting full diff yet; only status
  printf '{"drift":%s}' "$DRIFT" > "$OUTPUT_JSON"
fi

if (( DRIFT )); then
  exit 1
fi
exit 0
