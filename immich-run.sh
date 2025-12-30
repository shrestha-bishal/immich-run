#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] --source <folder>

Options:
  -o, --organise               Run the media organisation
  -u, --upload TEMPLATE [ALBUM] Upload folder using specified immich-go template
  -s, --source PATH            Specify source folder (mandatory)
  -h, --help                   Show this help message

Notes:
  If the template requires an album ({{ALBUM}}), pass the album name as an additional argument after the template.
EOF
}

ORGANISE=false
UPLOAD_TEMPLATE=""
UPLOAD_ALBUM=""
SRC=""

# Argument parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--organise)
      ORGANISE=true
      shift
      ;;
    -u|--upload)
      if [[ -z "${2:-}" || "$2" == -* ]]; then
        UPLOAD_TEMPLATE="into_album"
        UPLOAD_ALBUM="Uploads"
        shift
      else
        UPLOAD_TEMPLATE="$2"
        if [[ -n "${3:-}" && "$3" != -* ]]; then
          UPLOAD_ALBUM="$3"
          shift
        fi
        shift 2
      fi
      ;;

    -s|--source)
      SRC="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Validate mandatory source
if [[ -z "$SRC" ]]; then
  echo "Error: --source <folder> is required"
  show_help
  exit 1
fi
if [[ ! -d "$SRC" ]]; then
  echo "Invalid folder path: $SRC"
  exit 1
fi

# Load .env
if [[ -f ".env" ]]; then
  export $(grep -v '^#' .env | xargs)
fi

# Step 1: Organise
if [[ "$ORGANISE" == true ]]; then
  echo "Running media organisation..."
  source ./scripts/organise.sh
  organise_media "$SRC"
fi

# Step 2: Upload
if [[ -n "$UPLOAD_TEMPLATE" ]]; then
  echo "Running upload with template '$UPLOAD_TEMPLATE'..."
  source ./scripts/upload.sh
  upload_to_immich "$SRC" "$UPLOAD_TEMPLATE" "$UPLOAD_ALBUM"
fi

echo "Completed."
