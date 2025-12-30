#!/usr/bin/env bash
set -euo pipefail

upload_to_immich() {
    local SRC="$1"
    local TEMPLATE="$2"
    local ALBUM="${3:-}"

    # Validate source folder
    if [[ ! -d "$SRC" ]]; then
        echo "Source folder does not exist: $SRC"
        return 1
    fi

    # Validate immich-go executable
    if [[ -z "${IMMICH_GO_EXECUTABLE:-}" ]]; then
        echo "IMMICH_GO_EXECUTABLE not set in .env"
        return 1
    fi
    if [[ ! -x "$IMMICH_GO_EXECUTABLE" ]]; then
        echo "IMMICH_GO_EXECUTABLE is not executable: $IMMICH_GO_EXECUTABLE"
        return 1
    fi

    # Validate server and API key
    if [[ -z "${IMMICH_SERVER:-}" || -z "${IMMICH_API_KEY:-}" ]]; then
        echo "IMMICH_SERVER and IMMICH_API_KEY must be set in .env"
        return 1
    fi

    # Base args
    local args=(upload from-folder --server "$IMMICH_SERVER" --api-key "$IMMICH_API_KEY")

    # Load template from .upload-templates.env if exists
    if [[ -f ".upload-templates.env" ]]; then
        source .upload-templates.env
        local TEMPLATE_FLAGS="${!TEMPLATE:-}"
        if [[ -n "$TEMPLATE_FLAGS" ]]; then
            # Replace {{ALBUM}} placeholder
            if [[ "$TEMPLATE_FLAGS" == *"{{ALBUM}}"* ]]; then
                if [[ -z "$ALBUM" ]]; then
                    echo "Error: Template '$TEMPLATE' requires an album name"
                    return 1
                fi
                TEMPLATE_FLAGS="${TEMPLATE_FLAGS//\{\{ALBUM\}\}/\"$ALBUM\"}"
            fi
            args+=($TEMPLATE_FLAGS)
        fi
    fi

    # Predefined template handling if not in .upload-templates.env
    case "$TEMPLATE" in
        into_album_tag)
            [[ -z "$ALBUM" ]] && { echo "Error: into_album_tag requires album name"; return 1; }
            args+=(--into-album "$ALBUM" --folder-as-tags)
            ;;
        into_album)
            [[ -z "$ALBUM" ]] && { echo "Error: into_album requires album name"; return 1; }
            args+=(--into-album "$ALBUM")
            ;;
        album_by_folder_tag)
            args+=(--folder-as-album FOLDER --folder-as-tags)
            ;;
        album_by_path_tag)
            args+=(--folder-as-album PATH --folder-as-tags)
            ;;
        dry_run)
            args+=(--dry-run)
            ;;
        *)
            if [[ -z "${TEMPLATE_FLAGS:-}" ]]; then
                echo "Error: Unknown upload template '$TEMPLATE'"
                return 1
            fi
            ;;
    esac

    echo "Uploading:"
    echo "  Source  : $SRC"
    echo "  Template: $TEMPLATE"
    [[ -n "$ALBUM" ]] && echo "  Album   : $ALBUM"

    "$IMMICH_GO_EXECUTABLE" "${args[@]}" "$SRC"

    echo "Upload complete."
}
