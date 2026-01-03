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

  # Check if any GoPro files exist
  if compgen -G "$SRC"/GX*.{mp4,MP4} >/dev/null || compgen -G "$SRC"/GL*.{lrv,LRV} >/dev/null; then
      mkdir -p "$GOPRO_DIR"

      # Handle GX MP4s and delete matching GL LRVs
      for gx in "$SRC"/GX*.{mp4,MP4}; do
          [[ -f "$gx" ]] || continue
          gx_fname="$(basename "$gx")"
          gx_num="${gx_fname:2}"        # strip GX
          gx_num="${gx_num%.*}"         # remove extension

          # Delete matching GL LRV
          for gl in "$SRC"/GL*.[lL][rR][vV]; do
              [[ -f "$gl" ]] || continue
              gl_fname="$(basename "$gl")"
              gl_num="${gl_fname:2}"        # strip GL
              gl_num="${gl_num%.*}"         # remove extension

              if [[ "$gx_num" == "$gl_num" ]]; then
                  echo "Deleting matching GL LRV: $gl_fname"
                  rm -f "$gl"
              fi
          done

          echo "Moving GX MP4: $gx_fname"
          mv "$gx" "$GOPRO_DIR/"
      done

      # Move orphaned GL LRVs
      for gl in "$SRC"/GL*.[lL][rR][vV]; do
          [[ -f "$gl" ]] || continue
          gl_fname="$(basename "$gl")"
          gl_num="${gl_fname:2}"        # strip GL
          gl_num="${gl_num%.*}"         # remove extension

          # Skip if matching GX MP4 exists
          if compgen -G "$SRC/GX$gl_num.{mp4,MP4}" >/dev/null; then
              continue
          fi

          echo "Moving orphan GL LRV: $gl_fname"
          mv "$gl" "$GOPRO_DIR/"
      done
  fi
    
  ## Collect photos (case-insensitive)
  for f in "$SRC"/*.{jpg,JPG,jpeg,JPEG,heic,HEIC,png,PNG,nef,NEF,cr2,CR2}; do
    [[ -f "$f" ]] || continue
    base="$(basename "${f%.*}")"
    PHOTOS["$base"]="$f"
  done

  ## Collect videos (case-insensitive)
  for f in "$SRC"/*.{mov,MOV,mp4,MP4,3gp}; do
    [[ -f "$f" ]] || continue
    base="$(basename "${f%.*}")"
    MOVS["$base"]="$f"
  done

  ## Process videos & Live Photos
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

  ## Remaining photos
  for base in "${!PHOTOS[@]}"; do
    if [[ -z "${MOVS[$base]:-}" ]]; then
      [[ -d "$PHOTO_DIR" ]] || mkdir -p "$PHOTO_DIR"
      echo "Photo detected: $base"
      mv "${PHOTOS[$base]}" "$PHOTO_DIR/"
    fi
  done

  ## Delete .aae and .THM files (case-insensitive)
  for f in "$SRC"/*.{AAE,aae,THM,thm}; do
    [[ -f "$f" ]] || continue
    echo "Deleting file: $(basename "$f")"
    rm -f "$f"
  done

  shopt -u nullglob nocaseglob
  echo "Organisation Completed."
}
