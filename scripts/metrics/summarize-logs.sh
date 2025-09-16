#!/usr/bin/env bash
# Summarize structured log JSONL produced by log-json.sh integrations.
# Provides counts per source/result and basic duration stats.

set -euo pipefail
FILE=${1:-}
[[ -n $FILE ]] || { echo "Usage: $0 <log.jsonl>" >&2; exit 2; }
[[ -f $FILE ]] || { echo "Missing file $FILE" >&2; exit 3; }

# Use awk for lightweight JSON field extraction (assumes flat one-line objects with simple string values)
awk '
function get(k) {
  # match "k":"value"
  if ($0 ~ "\"" k "\"\\":") {
    match($0, "\"" k "\"\\":\"[^"]*\"", a)
    if (a[0] != "") {
      sub(/^[^"]*\"/, "", a[0]); sub(/\"$/, "", a[0]); return a[0];
    }
  }
  return "";
}
{
  src=get("source"); res=get("result"); phase=get("phase"); dur=get("duration_ms");
  if(src!="") sources[src]++;
  if(res!="") results[src ":" res]++;
  if(dur!="" && dur ~ /^[0-9]+$/){ total_dur[src]+=dur; counts_dur[src]++; if(min_dur[src]==""||dur<min_dur[src])min_dur[src]=dur; if(dur>max_dur[src])max_dur[src]=dur; }
}
END{
  print "=== Sources ===";
  for(s in sources){ print s, sources[s]; }
  print "\n=== Results ===";
  for(r in results){ print r, results[r]; }
  print "\n=== Durations (ms) ===";
  for(s in total_dur){ avg= (counts_dur[s]>0)? int(total_dur[s]/counts_dur[s]):0; print s, "count=" counts_dur[s] " avg=" avg " min=" min_dur[s] " max=" max_dur[s]; }
}' "$FILE"
