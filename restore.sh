#!/bin/bash
set -euo pipefail

leave(){
    exit 1
}

get_filename(){
    FILE=$1

    nome_com_extensao="${FILE##*/}"
    nome_apenas="${nome_com_extensao%%.*}"

    echo "$nome_apenas"
}

cleanup(){
    echo "Leaving..."
}

trap cleanup EXIT

CONFIG_FILE="config.yml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "invalid config file: '$CONFIG_FILE'"
    leave
fi

BKP_FILE_PATH="$(yq -r '.restore.bkp-file-path' $CONFIG_FILE)"
KEY_PATH="$(yq -r '.restore.key-path' $CONFIG_FILE)"
DEST_DIR="$(yq -r '.restore.dest-dir' $CONFIG_FILE)"

if [ ! -f "$BKP_FILE_PATH" ]; then
    echo "Invalid bkp-file-path: '$BKP_FILE_PATH'"
    leave
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "invalid key-path: '$KEY_PATH'"
    leave
fi

BKP_FILE_PATH_NAME=$(get_filename "$BKP_FILE_PATH")
DEST_DIR_NAME="$DEST_DIR/$BKP_FILE_PATH_NAME"

echo "Starting restoration"

mkdir -p "$DEST_DIR_NAME"

if [ $? -ne 0 ]; then
    echo "dest-dir '$DEST_DIR_NAME' could not be created"
    leave
fi

age -d -i "$KEY_PATH" "$BKP_FILE_PATH" | tar -xzf - -C "$DEST_DIR_NAME"

echo "Backup restored to $DEST_DIR_NAME"
