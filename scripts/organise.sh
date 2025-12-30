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

  shopt -s nullglob nocaseglob

  ### Move GoPro files (GX*.MP4 / GX*.LRV)
  for f in "$SRC"/GX*.{mp4,lrv}; do
    [[ -d "$GOPRO_DIR" ]] || mkdir -p "$GOPRO_DIR"
    echo "GoPro file detected: $(basename "$f")"
    mv "$f" "$GOPRO_DIR/"
  done

  # Photos
  for f in "$SRC"/*.{jpg,jpeg,heic,png}; do
    base="$(basename "${f%.*}")"
    PHOTOS["$base"]="$f"
  done

  # Videos
  for f in "$SRC"/*.mov; do
    base="$(basename "${f%.*}")"
    MOVS["$base"]="$f"
  done

  ### Process files
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

  echo "Organisation Completed."
}

# Delete any .aae files in the source folder
shopt -s nullglob
for f in "$SRC"/*.{AAE,THM}; do
  echo "Deleting file: $(basename "$f")"
  rm -f "$f"
done
shopt -u nullglob
