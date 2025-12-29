#!/usr/bin/env bash
set -euo pipefail

# Function: upload_to_immich
# Arguments:
#   $1 = source folder
#   $2 = template name
#   $3 = optional album name (only needed if template has {{ALBUM}})
upload_to_immich() {
    local SRC="$1"
    local TEMPLATE="$2"
    local ALBUM_NAME="${3:-}"   # optional

    # Validate source folder
    if [[ ! -d "$SRC" ]]; then
        echo "Source folder does not exist: $SRC"
        return 1
    fi

    # Load template file
    if [[ ! -f "upload-templates.env" ]]; then
        echo "Template file upload-templates.env not found"
        return 1
    fi
    source upload-templates.env

    # Get template flags
    local TEMPLATE_FLAGS="${!TEMPLATE:-}"
    if [[ -z "$TEMPLATE_FLAGS" ]]; then
        echo "Template '$TEMPLATE' not found in upload-templates.env"
        return 1
    fi

    # Replace {{ALBUM}} placeholder if present
    if [[ "$TEMPLATE_FLAGS" == *"{{ALBUM}}"* ]]; then
        if [[ -z "$ALBUM_NAME" ]]; then
            echo "Error: Template '$TEMPLATE' requires an album name"
            return 1
        fi
        TEMPLATE_FLAGS="${TEMPLATE_FLAGS//\{\{ALBUM\}\}/$ALBUM_NAME}"
    fi

    # Validate immich-go executable from .env
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

    # Run immich-go
    echo "Uploading '$SRC' using template '$TEMPLATE'..."
    "$IMMICH_GO_EXECUTABLE" upload from-folder \
        --server "$IMMICH_SERVER" \
        --api-key "$IMMICH_API_KEY" \
        $TEMPLATE_FLAGS \
        "$SRC"

    echo "Upload complete."
}
