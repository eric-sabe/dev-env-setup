#!/usr/bin/env bash
# Doc Generator: Emits TOOLS_MATRIX.md and updates README section between AUTOGEN markers.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/tools*}"
VERSIONS_FILE="${ROOT_DIR}/manifests/versions.yaml"
MATRIX_FILE="${ROOT_DIR}/TOOLS_MATRIX.md"
README_FILE="${ROOT_DIR}/README.md"

if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "versions.yaml not found at $VERSIONS_FILE" >&2
  exit 1
fi

parse_section() {
  awk "/^$1:/,/^[A-Za-z0-9_-]+:/" "$VERSIONS_FILE" | sed '1d;$d' || true
}

emit_python_table() {
  echo "### Python Package Groups"; echo
  echo '| Group | Package | Pin |'
  echo '|-------|---------|-----|'
  awk '
    /^python:/ {inpy=1; next}
    /^node:/ {exit}
    function trim(s){ sub(/^ +/,"",s); sub(/ +$/,"",s); return s }
    inpy {
      if ($0 ~ /^[ ]{4}[A-Za-z0-9_-]+:[ ]*$/) {
        line=$0; sub(/^[ ]{4}/,"",line); sub(/:.*/,"",line); top=line; nested=""; next
      } else if (top=="extras" && $0 ~ /^[ ]{6}[A-Za-z0-9_-]+:[ ]*$/) {
        line=$0; sub(/^[ ]{6}/,"",line); sub(/:.*/,"",line); nested=line; next
      } else if ($0 ~ /^[ ]{6}[A-Za-z0-9_.@-]+:[ ]*"?[^"#]+"?[ ]*$/) {
        line=$0; sub(/^[ ]{6}/,"",line); name=line; sub(/:.*/,"",name); pin=line; sub(/^[^:]+:[ ]*/,"",pin); gsub(/[ "\t]/,"",pin);
        if (top!="extras") {
          printf("| %s | %s | %s |\n", top, name, pin);
        } else if (nested!="") {
          printf("| extras.%s | %s | %s |\n", nested, name, pin);
        }
        next
      } else if ($0 ~ /^[ ]{8}[A-Za-z0-9_.@-]+:[ ]*"?[^"#]+"?[ ]*$/) {
        if (top=="extras" && nested!="") {
          line=$0; sub(/^[ ]{8}/,"",line); name=line; sub(/:.*/,"",name); pin=line; sub(/^[^:]+:[ ]*/,"",pin); gsub(/[ "\t]/,"",pin);
          printf("| extras.%s | %s | %s |\n", nested, name, pin);
        }
        next
      }
    }
  ' "$VERSIONS_FILE"
  echo
}

emit_node_table() {
  echo '### Node Global Packages'; echo
  echo '| Package | Pin |'
  echo '|---------|-----|'
  awk '/node:/,/^linux:/' "$VERSIONS_FILE" | awk '/globals:/,/^linux:/' | \
    grep -E '^[[:space:]]+[A-Za-z0-9_@\-]+:' | grep -v 'globals:' | \
    sed -E 's/^[[:space:]]*//; s/"//g' | while IFS=: read -r name ver; do
      ver=$(echo "$ver" | xargs)
      echo "| $name | $ver |"
    done
  echo
}

emit_profiles_table() {
  echo '### Profiles'; echo
  echo '| Profile | Python Groups | Node Globals |'
  echo '|---------|---------------|--------------|'
  # Collect profile blocks by simple state machine to avoid complex awk quoting pitfalls
  awk '/^profiles:/,0' "$VERSIONS_FILE" | while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
      # flush previous
      if [[ -n "${_cur_profile:-}" ]]; then
        py_display=${_cur_python:-'-'}
        node_display=${_cur_node:-'-'}
        echo "| $_cur_profile | $py_display | $node_display |"
      fi
      _cur_profile="${BASH_REMATCH[1]}"; _cur_python=""; _cur_node=""; continue
    fi
    if [[ -n "${_cur_profile:-}" ]]; then
      if [[ $line =~ python:[[:space:]]*\[(.*)\] ]]; then
        val=${BASH_REMATCH[1]// /}
        _cur_python="$val"
      elif [[ $line =~ node_globals:[[:space:]]*\[(.*)\] ]]; then
        val=${BASH_REMATCH[1]// /}
        _cur_node="$val"
      fi
    fi
  done
  # emit last profile
  if [[ -n "${_cur_profile:-}" ]]; then
    py_display=${_cur_python:-'-'}
    node_display=${_cur_node:-'-'}
    echo "| $_cur_profile | $py_display | $node_display |"
  fi
  echo
}

build_matrix() {
  {
    echo '# Tools & Versions Matrix'
    echo
    emit_python_table
    emit_node_table
    emit_profiles_table
  } >"$MATRIX_FILE"
  echo "Generated $MATRIX_FILE"
}

update_readme_section() {
  local begin='<!-- AUTOGEN:TOOLS_MATRIX:BEGIN -->'
  local end='<!-- AUTOGEN:TOOLS_MATRIX:END -->'
  if ! grep -q "$begin" "$README_FILE"; then
    echo "Markers not found in README.md" >&2; return 1; fi
  local tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" -v file="$MATRIX_FILE" '
    BEGIN{printed=0}
    $0~b{print;print ""; while((getline line<file)>0) print line; printed=1; skip=1; next}
    $0~e{skip=0}
    skip!=1 {print}
  ' "$README_FILE" > "$tmp"
  mv "$tmp" "$README_FILE"
  echo "Updated README.md tools matrix section"
}

build_matrix
update_readme_section
