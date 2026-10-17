#!/bin/bash
set -euo pipefail

CONFIG_FILE="config.yml"

PROJECTS_DIR="$(yq -r '.projects-directory' $CONFIG_FILE)"
PROJECTS_BKP_COMMAND="$(yq -r '.projects-backup-command' $CONFIG_FILE)"

CURRENT_TIMESTAMP="$(date +'%Y-%m-%d')"
TMP_DIR="/tmp/backup-$CURRENT_TIMESTAMP"
BACKUP_DIRECTORY="$(yq -r '.backup-directory' $CONFIG_FILE)"
AGE_RECIPIENT="$(yq -r '.age-recipient' $CONFIG_FILE)"

cleanup() {
    echo "Deleting $TMP_DIR"
    rm -rf -- "$TMP_DIR"
}

trap cleanup EXIT

leave() {
    echo $1
    exit 1
}

echo "Creating $TMP_DIR"
mkdir -p "$TMP_DIR"

echo "Copying backup project"
cp * "$TMP_DIR/"

# Iterando por diretórios
while IFS=$'\t' read -r DIR_NAME DIR; do
    echo "Processing $DIR_NAME: $DIR"

    DIR_BACKUP_PATH="$TMP_DIR/directories/$DIR_NAME"
    
    if [[ ! -d "$DIR" ]]; then
        leave "The path '$DIR' does not exist or is not a valid directory"
    fi
    
    mkdir -p "$DIR_BACKUP_PATH"
    cp -a "$DIR/." "$DIR_BACKUP_PATH/"
done < <(yq -r '.directories | to_entries | .[] | [.key, .value] | @tsv' "$CONFIG_FILE")
echo "Directories processed"

# Iterando por projetos
for PROJECT in $(yq -r '.projects[]' "$CONFIG_FILE"); do
    echo "Processing $PROJECT"

    PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
    PROJECT_BACKUP_PATH="$TMP_DIR/projects/$PROJECT"
    
    if [[ ! -d "$PROJECT_PATH" ]]; then
        leave "The project path '$PROJECT_PATH' does not exist or is not a valid directory"
    fi

    mkdir -p "$PROJECT_BACKUP_PATH"
    make -C "$PROJECT_PATH" "$PROJECTS_BKP_COMMAND" BKP_DIR="$PROJECT_BACKUP_PATH"
done
echo "Projects processed"

# Gerando arquivo final
echo "Compacting everything"
mkdir -p -m 700 "$BACKUP_DIRECTORY"
tar -czf - -C "$TMP_DIR" . | age -r "$AGE_RECIPIENT" -o "$BACKUP_DIRECTORY/$CURRENT_TIMESTAMP.tar.gz.age"
echo "Everything done"
