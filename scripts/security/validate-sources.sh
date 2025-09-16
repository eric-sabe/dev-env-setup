#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
YAML="$ROOT_DIR/manifests/versions.yaml"
STRICT=0
JSON_OUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --strict) STRICT=1; shift;;
    --output-json) JSON_OUT="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $YAML ]] || { echo "missing manifest: $YAML" >&2; exit 3; }

# naive parse: look for lines under sources: containing sha256:
current_section=""
missing=0
mapfile -t entries < <(awk '/^sources:/,0 {print}' "$YAML" | grep -E '^( {2,}.+name:| {2,}.+sha256: )')
name=""
sha=""
report=()
for line in "${entries[@]}"; do
  if [[ $line =~ name: ]]; then
    name=$(echo "$line" | sed -E 's/.*name: *"?([^" ]+)"?.*/\1/')
  elif [[ $line =~ sha256: ]]; then
    sha=$(echo "$line" | sed -E 's/.*sha256: *([^ #]+).*/\1/')
    if [[ $sha == "TBD" ]]; then
      missing=$((missing+1))
      report+=("$name|missing")
    else
      report+=("$name|ok")
    fi
    name=""; sha=""
  fi
done

if [[ -n $JSON_OUT ]]; then
  {
    echo '{'
    echo '  "status": '"\"$([[ $STRICT -eq 1 && $missing -gt 0 ]] && echo fail || echo pass)\""','
    echo '  "missing": '"$missing"','
    echo '  "entries": ['
    for i in "${!report[@]}"; do
      n="${report[$i]%%|*}"; s="${report[$i]#*|}";
      printf '    {"name": "%s", "state": "%s"}%s\n' "$n" "$s" $([[ $i -lt $((${#report[@]}-1)) ]] && echo ',')
    done
    echo '  ]'
    echo '}'
  } > "$JSON_OUT"
fi

if [[ $STRICT -eq 1 && $missing -gt 0 ]]; then
  echo "Missing $missing checksum(s)" >&2
  exit 4
fi

echo "Source validation: $missing missing checksum(s)" >&2
