#!/usr/bin/env bash
# Stages the Workshop upload folder in ~/Zomboid/Workshop/SoapyWater.
# Upload it from the game: main menu -> Workshop -> SoapyWater.
set -euo pipefail
cd "$(dirname "$0")"
DEST="$HOME/Zomboid/Workshop/SoapyWater"
rm -rf "$DEST"
mkdir -p "$DEST/Contents/mods/SoapyWater"
cp workshop/workshop.txt workshop/preview.png "$DEST/"
cp -r 42 common "$DEST/Contents/mods/SoapyWater/"
find "$DEST" -type f | sort
