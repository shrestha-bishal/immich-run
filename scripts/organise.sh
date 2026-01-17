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
  for f in "$SRC"/*.{jpg,JPG,jpeg,JPEG,heic,HEIC,png,PNG,nef,NEF,cr2,CR2,arw,ARW}; do
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

flatten_subfolders() {
  local ROOT="$1"
  [[ -d "$ROOT" ]] || return 1

  shopt -s nullglob

  # Process deepest directories first
  while IFS= read -r -d '' dir; do
    [[ "$dir" == "$ROOT" ]] && continue

    local move_failed=0

    for file in "$dir"/*; do
      [[ -f "$file" ]] || continue

      filename="$(basename "$file")"
      target="$ROOT/$filename"

      # Handle name collisions
      if [[ -e "$target" ]]; then
        base="${filename%.*}"
        ext="${filename##*.}"
        [[ "$base" == "$ext" ]] && ext=""

        i=1
        while [[ -e "$ROOT/${base}_$i${ext:+.$ext}" ]]; do
          ((i++))
        done

        newname="${base}_$i${ext:+.$ext}"
        echo "Renaming: $filename → $newname"

        if ! mv -- "$file" "$ROOT/$newname"; then
          echo "Failed to move: $file"
          move_failed=1
        fi
      else
        if ! mv -- "$file" "$ROOT/"; then
          echo "Failed to move: $file"
          move_failed=1
        fi
      fi
    done

    # Remove directory ONLY if empty AND no failures
    if [[ "$move_failed" -eq 0 && -z "$(ls -A "$dir")" ]]; then
      echo "Removing empty folder: $dir"
      rmdir -- "$dir"
    fi
  done < <(find "$ROOT" -type d -depth -print0)

  shopt -u nullglob
}

rename_collisions_as_pairs() {
  local ROOT="$1"
  shopt -s nullglob nocaseglob

  echo "Scanning for potential collisions and syncing pairs..."

  # Find all files in subfolders (level 2 or deeper)
  find "$ROOT" -mindepth 2 -type f -print0 | while IFS= read -r -d '' file; do
    # Skip if file was already moved/renamed by a previous iteration in this loop
    [[ -f "$file" ]] || continue

    local dir="$(dirname "$file")"
    local fname="$(basename "$file")"
    local base="${fname%.*}"
    local ext="${fname##*.}"
    
    # Define what we consider "pairable" extensions
    local pair_extensions=("jpg" "jpeg" "heic" "png" "mov" "mp4")

    # 1. CHECK BOTH WAYS: Does this name (with ANY media extension) exist in ROOT?
    local collision_detected=0
    for p_ext in "${pair_extensions[@]}"; do
      if [[ -e "$ROOT/$base.$p_ext" ]]; then
        collision_detected=1
        break
      fi
    done

    if [[ "$collision_detected" -eq 1 ]]; then
      # 2. Find a suffix that is free for ALL potential extensions in the ROOT
      local i=1
      local found_safe_name=0
      while [[ "$found_safe_name" -eq 0 ]]; do
        found_safe_name=1
        for p_ext in "${pair_extensions[@]}"; do
          if [[ -e "$ROOT/${base}_$i.$p_ext" ]]; then
            found_safe_name=0
            ((i++))
            break
          fi
        done
      done

      local new_base="${base}_$i"
      echo "Collision risk for '$base' -> Renaming pair to '$new_base' in subfolder"

      # 3. Rename ALL files in the CURRENT subfolder that share this base name
      # This catches the photo, the video, and even things like sidecars
      for sub_file in "$dir/$base".*; do
        [[ -f "$sub_file" ]] || continue
        local sub_ext="${sub_file##*.}"
        mv -- "$sub_file" "$dir/${new_base}.${sub_ext}"
      done
    fi
  done
  shopt -u nullglob nocaseglob
}