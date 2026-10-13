# VPS Backups

Scripts to back up this VPS into a single encrypted file and to restore it.
`backup.sh` collects configured directories and project backups, then packs and encrypts everything with `age`. `restore.sh` decrypts and extracts that file.

## Requirements

- `bash`
- `yq` (reads `config.yml`)
- `tar` and `gzip`
- `age`
- `make` (runs each project's backup target)
- Read access to every configured path. Paths under `/etc` usually require running as root.

## Configuration (`config.yml`)

Both scripts are configured only through `config.yml`, which `backup.sh` reads from the **current directory**.

| Key | Meaning |
|---|---|
| `version` | Config format version. Informational only; not read by the scripts. |
| `projects-directory` | Parent directory that contains one folder per project. |
| `projects-backup-command` | `make` target run inside each project folder to produce its backup. |
| `backup-directory` | Where the final encrypted backup file is written. Created with mode `700` if it does not exist. |
| `age-recipient` | `age` public key used to encrypt the backup. |
| `directories` | Map of `name: path`. Each path's content is copied into the backup under `directories/<name>/`. |
| `projects` | List of project folder names inside `projects-directory`. |

Example:

```yaml
version: 1.0.0

projects-directory: /home/grodrigues/projetos
projects-backup-command: "bkp"
backup-directory: "/var/bkp"
age-recipient: "age1..."

directories:
  cron: /etc/cron.d
  # nginx: /etc/nginx

projects:
  - kanban
  # - edudict
```

### Project backup contract

For each entry in `projects`, `backup.sh` runs:

```bash
make -C <projects-directory>/<project> <projects-backup-command> BKP_DIR=<temporary folder>
```

The project's `Makefile` decides what to save (for example, a database dump or uploaded files) and must write it into `$(BKP_DIR)`. Each project included in the backup needs that target.

## Running a backup

From this directory:

```bash
./backup.sh
```

The script has no options. What it does:

1. Creates a temporary folder `/tmp/backup-<timestamp>`.
2. Copies the content of every entry in `directories` (`cp -a`, preserving permissions and timestamps).
3. Runs the backup target of every entry in `projects`.
4. Packs the temporary folder with `tar` + `gzip`, encrypts it with `age` and writes:

   ```text
   <backup-directory>/bkp-YYYY-MM-DD-HH-MM-SS.tar.gz.age
   ```

5. Deletes the temporary folder, also when the script fails.

The script stops with an error if a configured directory or project folder does not exist, or if a copy or a project's backup target fails. Those checks happen before the final file is created, so in that case no backup file is written.

Content of the backup file once decrypted and extracted:

```text
directories/
  <name>/        # one per entry in `directories`
projects/
  <project>/     # whatever that project's backup target wrote
```

## Restoring

```bash
./restore.sh <backup-file-path> <age-private-key-path> <destination-directory>
```

Example:

```bash
./restore.sh /var/bkp/bkp-2026-10-13-03-00-00.tar.gz.age ~/keys/backup.key /tmp/restore-test
```

The script creates the destination directory if needed, decrypts the file with the private key and extracts it there, producing the `directories/` and `projects/` layout above.

It does **not** put anything back in its original location and does not restore databases. Copying files back and importing project data (for example, loading a database dump) are manual steps.

## Encryption keys

- The VPS only needs the `age` public key (`age-recipient`) to create backups.
- The matching private key is needed only to restore. Keep it somewhere safe **outside** the VPS; without it the backups cannot be read.

## Not implemented

- Upload to remote storage (e.g. rclone). Backups stay only in `backup-directory` on the VPS.
- Rotation or deletion of old backups.
- Command-line options such as dry run or backing up a single project.
- Scheduling. Run the script manually or add it to cron yourself.

## Restore rule

A backup is not trusted until it has been restored successfully in a test location and its content (directory files and project data) has been checked.
