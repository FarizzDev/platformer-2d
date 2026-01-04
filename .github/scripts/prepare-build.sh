#!/bin/bash
set -e

if [ ! -f export_presets.cfg ]; then
  echo "Error: File export_presets.cfg not found."
  exit 1
fi

# Determine if any Android build is happening
if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  ISANDROID=$(grep -q 'platform="Android"' export_presets.cfg && echo "true")
else
  # Check if the selected preset is an Android preset
  ISANDROID=$(awk -v preset_name="$PRESET_NAME" '
    BEGIN { FS = "[[:space:]]*=[[:space:]]*"; in_preset=0; is_android=0 }
    /^\[preset\./ { in_preset=0 }
    /^name[[:space:]]*=/ {
      n=$2; gsub(/"/, "", n)
      if (n == preset_name) in_preset=1
    }
    in_preset && /^platform[[:space:]]*=/ {
      p=$2; gsub(/"/, "", p)
      if (p == "Android") { is_android=1 }
    }
    END { if (is_android) print "true" }
  ' export_presets.cfg)
fi

echo "ISANDROID=${ISANDROID:-false}" >>"$GITHUB_ENV"

VERSION=$(echo "$GODOT_LINK" | sed -E 's|.*\/([0-9.]+)-([a-z0-9]+).*|\1.\2|')
echo "VERSION=$VERSION" >>"$GITHUB_ENV"
