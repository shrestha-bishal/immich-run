#!/usr/bin/env bash
set -euo pipefail

### Load env
if [[ -f ".env" ]]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found"
  exit 1
fi

### Ask for source folder
read -rp "Enter source folder path: " SRC

if [[ ! -d "$SRC" ]]; then
  echo "Invalid folder path"
  exit 1
fi

### Destination folders
PHOTO_DIR="$SRC/photos"
VIDEO_DIR="$SRC/videos"
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

# Photos: jpg, jpeg, heic
for f in "$SRC"/*.{jpg,jpeg,heic}; do
  base="$(basename "${f%.*}")"
  PHOTOS["$base"]="$f"
done

# Videos: mov
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

### Remaining photos (photo only)
for base in "${!PHOTOS[@]}"; do
  if [[ -z "${MOVS[$base]:-}" ]]; then
    [[ -d "$PHOTO_DIR" ]] || mkdir -p "$PHOTO_DIR"

    echo "Photo detected: $base"
    mv "${PHOTOS[$base]}" "$PHOTO_DIR/"
  fi
done

echo "Done."