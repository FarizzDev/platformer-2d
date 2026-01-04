#!/bin/bash
set -e

DEBUG_KEYSTORE_PATH=$(awk -F'=' -v target="\"$PRESET_NAME\"" '
    { sub(/\r$/, "") }
    /^\[preset\.[0-9]+\]$/ { in_target = 0 }
    
    $1 == "name" && $2 == target { in_target = 1 }
    in_target && $1 == "keystore/debug" {
        gsub(/"/, "", $2); gsub(/res:\/\//, "", $2);
        val = $2; exit
    }

    END { print (val ? val : "debug.keystore") }
' export_presets.cfg)

RELEASE_KEYSTORE_PATH=$(awk -F'[[:space:]]*=[[:space:]]*' -v target="\"$PRESET_NAME\"" '
    { sub(/\r$/, "") }
    /^\[preset\.[0-9]+\]$/ { in_target = 0 }

    $1 == "name" && $2 == target { in_target = 1 }
    in_target && $1 == "keystore/release" {
        gsub(/"/, "", $2); gsub(/res:\/\//, "", $2);
        val =  $2; exit
    }
    
    END { print (val ? val : "release.keystore") }
' export_presets.cfg)

echo "DEBUG_KEYSTORE_PATH=$DEBUG_KEYSTORE_PATH" >>"$GITHUB_ENV"
echo "RELEASE_KEYSTORE_PATH=$RELEASE_KEYSTORE_PATH" >>"$GITHUB_ENV"

mkdir -p "$(dirname "$RELEASE_KEYSTORE_PATH")"
mkdir -p "$(dirname "$DEBUG_KEYSTORE_PATH")"

if [[ -n "$RELEASE_KEYSTORE_BASE64" ]]; then
  echo ">>> Decoding existing keystore..."
  echo "$RELEASE_KEYSTORE_BASE64" | base64 --decode >"$RELEASE_KEYSTORE_PATH"

elif [[ "$DEBUG" == "false" ]]; then
  echo ">>> Generating release keystore..."

  rm -f "$RELEASE_KEYSTORE_PATH"
  keytool -genkey -v -noprompt \
    -keystore "$RELEASE_KEYSTORE_PATH" \
    -alias "$KEYSTORE_USER" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -dname "CN=$CERT_CN,O=$ORG,C=$COUNTRY" \
    -keyalg RSA -keysize 2048 -validity 10000
fi

if [[ ! -f "$DEBUG_KEYSTORE_PATH" ]]; then
  echo ">>> Generating debug keystore..."
  keytool -genkey -v -noprompt \
    -keystore "$DEBUG_KEYSTORE_PATH" \
    -alias androiddebugkey \
    -storepass android \
    -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 9000
fi
