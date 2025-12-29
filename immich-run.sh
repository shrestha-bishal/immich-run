#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] --source <folder>

Options:
  -o, --organise      Run the media organisation
  -s, --source PATH   Specify source folder
  -h, --help          Show this help message
EOF
}

ORGANISE=false
SRC=""

# Argument parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--organise)
      ORGANISE=true
      shift
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

# Validate source folder if organise is requested
if [[ "$ORGANISE" == true ]]; then
  if [[ -z "$SRC" ]]; then
    echo "Error: --source <folder> is required for organise"
    show_help
    exit 1
  fi
  if [[ ! -d "$SRC" ]]; then
    echo "Invalid folder path: $SRC"
    exit 1
  fi

  # Load .env if exists
  if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
  fi

  # Run organiser
  source ./scripts/organise.sh
  organise_media "$SRC"
fi
