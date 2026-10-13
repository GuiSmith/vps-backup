#!/bin/bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <backup-file-path> <age-private-key-path> <directory-destination-path>" >&2
    exit 1
fi

BKP_FILE_PATH="$1"
KEY_PATH="$2"
DEST_DIR="$3"

echo "Starting backup"

mkdir -p "$DEST_DIR"

age -d -i "$KEY_PATH" "$BKP_FILE_PATH" | tar -xzf - -C "$DEST_DIR"

echo "Backup restored to $DEST_DIR"
