#!/usr/bin/env bash
set -euo pipefail

organise_media() {
  local SRC="$1"

  if [[ ! -d "$SRC" ]]; then
    echo "Invalid folder path: $SRC"
    return 1
  fi

  PHOTO_DIR="$SRC/photo"
  VIDEO_DIR="$SRC/video"
  GOPRO_DIR="$SRC/gopro"

  declare -A PHOTOS
  declare -A MOVS
  declare -A GOPROS

  shopt -s nullglob nocaseglob

  ### Collect GoPro files (mp4 and lrv) - case insensitive
  for f in "$SRC"/GX*.{mp4,MP4,lrv,LRV}; do
    [[ -f "$f" ]] || continue
    base="${f%.*}"
    ext="${f##*.}"
    ext="${ext,,}"  # lowercase
    GOPROS["$base"]+="$ext "
  done

  ### Process GoPro files
  [[ -d "$GOPRO_DIR" ]] || mkdir -p "$GOPRO_DIR"
  for base in "${!GOPROS[@]}"; do
    exts=(${GOPROS[$base]})
    if [[ " ${exts[*]} " == *" mp4 "* ]]; then
      echo "GoPro MP4 found for $(basename "$base"): moving MP4"
      mv "$base.mp4" "$GOPRO_DIR/" 2>/dev/null || mv "$base.MP4" "$GOPRO_DIR/"
      [[ -f "$base.lrv" ]] && { echo "Deleting LRV for $(basename "$base")"; rm -f "$base.lrv"; }
      [[ -f "$base.LRV" ]] && { echo "Deleting LRV for $(basename "$base")"; rm -f "$base.LRV"; }
    elif [[ " ${exts[*]} " == *" lrv "* ]]; then
      echo "Only LRV found for $(basename "$base"): moving LRV"
      mv "$base.lrv" "$GOPRO_DIR/" 2>/dev/null || mv "$base.LRV" "$GOPRO_DIR/"
    fi
  done

  ### Collect photos (case-insensitive)
  for f in "$SRC"/*.{jpg,JPG,jpeg,JPEG,heic,HEIC,png,PNG}; do
    [[ -f "$f" ]] || continue
    base="$(basename "${f%.*}")"
    PHOTOS["$base"]="$f"
  done

  ### Collect videos (case-insensitive)
  for f in "$SRC"/*.{mov,MOV}; do
    [[ -f "$f" ]] || continue
    base="$(basename "${f%.*}")"
    MOVS["$base"]="$f"
  done

  ### Process videos & Live Photos
  for base in "${!MOVS[@]}"; do
    mov="${MOVS[$base]}"
    if [[ -n "${PHOTOS[$base]:-}" ]]; then
      [[ -d "$PHOTO_DIR" ]] || mkdir -p "$PHOTO_DIR"
      photo="${PHOTOS[$base]}"
      echo "Live Photo detected: $base"
      mv "$photo" "$PHOTO_DIR/"
      mv "$mov" "$PHOTO_DIR/"
    else
      [[ -d "$VIDEO_DIR" ]] || mkdir -p "$VIDEO_DIR"
      echo "Video detected: $base"
      mv "$mov" "$VIDEO_DIR/"
    fi
  done

  ### Remaining photos
  for base in "${!PHOTOS[@]}"; do
    if [[ -z "${MOVS[$base]:-}" ]]; then
      [[ -d "$PHOTO_DIR" ]] || mkdir -p "$PHOTO_DIR"
      echo "Photo detected: $base"
      mv "${PHOTOS[$base]}" "$PHOTO_DIR/"
    fi
  done

  ### Delete .aae and .THM files (case-insensitive)
  for f in "$SRC"/*.{AAE,aae,THM,thm}; do
    [[ -f "$f" ]] || continue
    echo "Deleting file: $(basename "$f")"
    rm -f "$f"
  done

  shopt -u nullglob nocaseglob
  echo "Organisation Completed."
}
