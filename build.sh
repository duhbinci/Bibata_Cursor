#!/bin/bash
# A script for preparing binaries of Bibata Cursors, created by Abdulkaiz Khatri.

version="v2.0.6"

error() (
  set -o pipefail
  "$@" 2> >(sed $'s,.*,\e[31m&\e[m,' >&2)
)

get_config_path() {
  local key="${1}"
  local cfg_path="configs"

  if [[ $key == *"Right"* ]]; then
    cfg_path="${cfg_path}/right"
  else
    cfg_path="${cfg_path}/normal"
  fi

  echo $cfg_path
}

with_version() {
  local comment="${1}"
  echo "$comment ($version)."
}

if ! type -p ctgen >/dev/null; then
  error ctgen
  exit 127 # exit program with "command not found" error code
fi

declare -A names
names["Bibata-Modern-Amber"]=$(with_version "Yellowish and rounded edge Bibata")
names["Bibata-Modern-Amber-Right"]=$(with_version "Yellowish and rounded edge right-hand Bibata")
names["Bibata-Modern-Classic"]=$(with_version "Black and rounded edge Bibata")
names["Bibata-Modern-Classic-Right"]=$(with_version "Black and rounded edge right-hand Bibata")
names["Bibata-Modern-Ice"]=$(with_version "White and rounded edge Bibata")
names["Bibata-Modern-Ice-Right"]=$(with_version "White and rounded edge right-hand Bibata")
names["Bibata-Original-Amber"]=$(with_version "Yellowish and sharp edge Bibata")
names["Bibata-Original-Amber-Right"]=$(with_version "Yellowish and sharp edge right-hand Bibata")
names["Bibata-Original-Classic"]=$(with_version "Black and sharp edge Bibata")
names["Bibata-Original-Classic-Right"]=$(with_version "Black and sharp edge right-hand Bibata")
names["Bibata-Original-Ice"]=$(with_version "White and sharp edge Bibata")
names["Bibata-Original-Ice-Right"]=$(with_version "White and sharp edge right-hand Bibata")
names["Bibata-Modern-Amethyst"]=$(with_version "Purple and rounded edge Bibata")
names["Bibata-Modern-Amethyst-Right"]=$(with_version "Purple and rounded edge right-hand Bibata")
names["Bibata-Original-Amethyst"]=$(with_version "Purple and sharp edge Bibata")
names["Bibata-Original-Amethyst-Right"]=$(with_version "Purple and sharp edge right-hand Bibata")

# Run up to $JOBS background jobs at once (defaults to CPU count)
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
throttle() {
  while (($(jobs -rp | wc -l) >= JOBS)); do wait -n; done
}
export XZ_OPT="-T0"

# Cleanup old builds
rm -rf themes bin

# Building Bibata XCursor + Windows binaries in parallel
for key in "${!names[@]}"; do
  comment="${names[$key]}"
  cfg_path=$(get_config_path "$key")

  throttle; ctgen "$cfg_path/x.build.toml" -p x11 -d "bitmaps/$key" -n "$key" -c "$comment XCursors" &
  throttle; ctgen "$cfg_path/win_rg.build.toml" -d "bitmaps/$key" -n "$key-Regular" -c "$comment Windows Cursors" &
  throttle; ctgen "$cfg_path/win_lg.build.toml" -d "bitmaps/$key" -n "$key-Large" -c "$comment Windows Cursors" &
  throttle; ctgen "$cfg_path/win_xl.build.toml" -d "bitmaps/$key" -n "$key-Extra-Large" -c "$comment Windows Cursors" &
done
wait

# Compressing Binaries
mkdir -p bin
cd themes || exit
cp ../LICENSE .

for key in "${!names[@]}"; do
  throttle; tar -cJf "../bin/${key}.tar.xz" "${key}" &
  throttle; zip -rq "../bin/${key}-Windows.zip" "${key}-Small-Windows" "${key}-Regular-Windows" "${key}-Large-Windows" "${key}-Extra-Large-Windows" &
done
throttle; tar -cJf "../bin/Bibata.tar.xz" --exclude="*-Windows" . &
wait

cd ..

# Copying License File for 'bitmaps'
cp LICENSE bitmaps/
zip -rq bin/bitmaps.zip bitmaps
