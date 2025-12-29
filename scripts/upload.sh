#!/usr/bin/env bash
set -euo pipefail

# Function: upload_to_immich
# Arguments:
#   $1 = source folder
#   $2 = template name
upload_to_immich() {
    local SRC="$1"
    local TEMPLATE="$2"

    # Validate source folder
    if [[ ! -d "$SRC" ]]; then
        echo "Source folder does not exist: $SRC"
        return 1
    fi

    # Load template file
    if [[ ! -f ".upload-templates.env" ]]; then
        echo "Template file upload-templates.env not found"
        return 1
    fi
    source .upload-templates.env

    # Get template flags
    TEMPLATE_FLAGS="${!TEMPLATE:-}"
    if [[ -z "$TEMPLATE_FLAGS" ]]; then
        echo "Template '$TEMPLATE' not found in upload-templates.env"
        return 1
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
