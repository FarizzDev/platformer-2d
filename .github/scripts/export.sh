#!/bin/bash
set -e
mkdir -p export

if [[ "$DEBUG" == "true" ]]; then
  EXPORT_FLAG="--export-debug"
else
  EXPORT_FLAG="--export"
fi

# Determine APK or AAB
get_android_ext() {
  local name_to_search="\"$1\""
  local fmt
  fmt=$(awk -F'[[:space:]]*=[[:space:]]*' -v target="$name_to_search" '
        { sub(/\r$/, "") }
        /^\[preset\.[0-9]+\]$/ { in_target = 0 }
        $1 == "name" && $2 == target { in_target = 1 }
        in_target && $1 == "custom_build/export_format" { print $2; exit }
    ' export_presets.cfg)

  [[ "$fmt" == "1" ]] && echo "aab" || echo "apk"
}

get_output_path() {
  local p_name="$1"
  local p_type="$2"
  local s_folder

  s_folder=$(echo "$p_type" | tr '[:upper:]' '[:lower:]' | cut -d'/' -f1 | tr -d '[:space:]')
  mkdir -p "export/$s_folder"

  case "$p_type" in
  "Android") echo "export/$s_folder/$FILE_BASENAME.$(get_android_ext "$p_name")" ;;
  "Windows Desktop") echo "export/$s_folder/$FILE_BASENAME.exe" ;;
  "Linux/X11") echo "export/$s_folder/$FILE_BASENAME" ;;
  "Mac OSX") echo "export/$s_folder/$FILE_BASENAME.zip" ;;
  "HTML5") echo "export/$s_folder/index.html" ;;
  *) echo "export/$s_folder/$FILE_BASENAME.bin" ;;
  esac
}

if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  # name|platform
  presets=$(awk -F'[[:space:]]*=[[:space:]]*' '/^name/ {n=$2; gsub(/"/,"",n)} /^platform/ {p=$2; gsub(/"/,"",p); print n"|"p}' export_presets.cfg)

  while IFS='|' read -r p_name p_type; do
    echo ">>> Exporting $p_name ($p_type)..."
    OUT=$(get_output_path "$p_name" "$p_type")
    godot $EXPORT_FLAG "$p_name" "$OUT"
  done <<<"$presets"
else
  # Export Single Preset
  echo ">>> Exporting $PRESET_NAME..."

  PLATFORM=$(awk -F'[[:space:]]*=[[:space:]]*' -v target="\"$PRESET_NAME\"" '$1=="name" && $2==target {found=1} found && $1=="platform" {gsub(/"/,"",$2); print $2; exit}' export_presets.cfg)

  OUT=$(get_output_path "$PRESET_NAME" "$PLATFORM")
  godot $EXPORT_FLAG "$PRESET_NAME" "$OUT"
fi

# Android Keystore
if [[ "$ISANDROID" == "true" && "$DEBUG" == "false" ]]; then
  cp "$RELEASE_KEYSTORE_PATH" export/android/ 2>/dev/null || true
fi

zip -r -7 "$FILE_BASENAME-build.zip" export/
