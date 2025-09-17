#!/usr/bin/env bash
# validate-sources.sh
# Purpose: Enforce checksum presence for deterministic, verifiable artifacts.
# Policy (1.0):
# - archives: All entries under manifests.archives must have a concrete sha256 (64-hex) and content_length.
# - sources: Package-manager types (pypi, npm) are informational and exempt; if a source points to a concrete
#   artifact URL (non package-manager), then a sha256 must be present.

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

missing=0
report=()

# Extract precise blocks to avoid bleeding into other top-level sections
archives_lines=$(awk 'BEGIN{inblk=0} 
  /^archives:/ {inblk=1; next}
  /^[[:alpha:]_]+:/ { if(inblk){exit} }
  { if(inblk) print }' "$YAML")
current_name=""; have_sha=""; have_len=""
while IFS= read -r l; do
  if [[ $l =~ ^[[:space:]]*-[[:space:]]name: ]]; then
    # evaluate previous
    if [[ -n $current_name ]]; then
      if [[ -z $have_sha || $have_sha == "TBD" || -z $have_len ]]; then
        missing=$((missing+1))
        report+=("archives:$current_name|missing")
      else
        report+=("archives:$current_name|ok")
      fi
    fi
    current_name=$(echo "$l" | sed -E 's/.*name: *([^ #]+)/\1/')
    have_sha=""; have_len=""
  elif [[ -n $current_name && $l =~ sha256: ]]; then
    have_sha=$(echo "$l" | awk '{print $2}')
  elif [[ -n $current_name && $l =~ content_length: ]]; then
    have_len=$(echo "$l" | awk '{print $2}')
  fi
done < <(printf "%s\n" "$archives_lines")
# tail entry
if [[ -n $current_name ]]; then
  if [[ -z $have_sha || $have_sha == "TBD" || -z $have_len ]]; then
    missing=$((missing+1))
    report+=("archives:$current_name|missing")
  else
    report+=("archives:$current_name|ok")
  fi
fi

# Validate sources block: enforce only for non-package-manager types
sources_lines=$(awk 'BEGIN{inblk=0}
  /^sources:/ {inblk=1; next}
  /^[[:alpha:]_]+:/ { if(inblk){exit} }
  { if(inblk) print }' "$YAML")
src_name=""; src_type=""; src_sha=""; src_url=""
while IFS= read -r l; do
  if [[ $l =~ ^[[:space:]]*-[[:space:]]name: ]]; then
    # evaluate previous
    if [[ -n $src_name ]]; then
      if [[ $src_type == "pypi" || $src_type == "npm" ]]; then
        report+=("sources:$src_name|skip")
      else
        if [[ -z $src_sha || $src_sha == "TBD" ]]; then
          missing=$((missing+1))
          report+=("sources:$src_name|missing")
        else
          report+=("sources:$src_name|ok")
        fi
      fi
    fi
    src_name=$(echo "$l" | sed -E 's/.*name: *"?([^" ]+)"?.*/\1/')
    src_type=""; src_sha=""; src_url=""
  elif [[ -n $src_name && $l =~ type: ]]; then
    src_type=$(echo "$l" | sed -E 's/.*type: *([^ #]+)/\1/')
  elif [[ -n $src_name && $l =~ sha256: ]]; then
    src_sha=$(echo "$l" | sed -E 's/.*sha256: *([^ #]+).*/\1/')
  elif [[ -n $src_name && $l =~ url: ]]; then
    src_url=$(echo "$l" | sed -E 's/.*url: *([^ #]+)/\1/')
  fi
done < <(printf "%s\n" "$sources_lines")
# tail entry
if [[ -n $src_name ]]; then
  if [[ $src_type == "pypi" || $src_type == "npm" ]]; then
    report+=("sources:$src_name|skip")
  else
    if [[ -z $src_sha || $src_sha == "TBD" ]]; then
      missing=$((missing+1))
      report+=("sources:$src_name|missing")
    else
      report+=("sources:$src_name|ok")
    fi
  fi
fi

# Emit JSON if requested
if [[ -n $JSON_OUT ]]; then
  {
    echo '{'
    echo '  "status": '"\"$([[ $STRICT -eq 1 && $missing -gt 0 ]] && echo fail || echo pass)\""','
    echo '  "missing": '"$missing"','
    echo '  "entries": ['
    for i in "${!report[@]}"; do
      n="${report[$i]%%|*}"; s="${report[$i]#*|}";
      printf '    {"entry": "%s", "state": "%s"}%s\n' "$n" "$s" $([[ $i -lt $((${#report[@]}-1)) ]] && echo ',')
    done
    echo '  ]'
    echo '}'
  } > "$JSON_OUT"
fi

if [[ $STRICT -eq 1 && $missing -gt 0 ]]; then
  echo "Missing $missing checksum(s) (archives or non-package-manager sources)" >&2
  for r in "${report[@]}"; do
    entry="${r%%|*}"; state="${r#*|}";
    [[ $state == missing ]] && echo "  - $entry" >&2
  done
  exit 4
fi

echo "Validation complete: $missing missing (archives + strict sources)" >&2
