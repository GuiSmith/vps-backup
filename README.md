# VPS Backups

This directory contains the backup configuration and documentation for this VPS.

Backup system location:

```text
/root/ops/backups/
```

Backup artifact output location:

```text
/var/backups/projects/YYYY-MM-DD/
```

## Intended backup types

1. Database backups
   - Use `pg_dump` against each project's Postgres container.
   - Credentials come from the project's env file.
   - Prefer `pg_dump -Fc` for restore flexibility.

2. Directory backups
   - Archive configured directories.
   - Compress first, then encrypt.
   - Upload the final encrypted artifacts with rclone.

## Expected backup layout

```text
/var/backups/projects/2026-07-21/
  manifest.json
  backup.log
  RESTORE.md
  kanban/
    databases/
    directories/
    metadata/
  edudict/
    databases/
    directories/
    metadata/
  vps/
    directories/
    metadata/
```

## Config file

Main config:

```text
/root/ops/backups/config.yml
```

Use it to map:

- project name -> database containers
- project name -> directories to archive
- `vps` -> server-level config such as Nginx, cron, systemd, Docker, firewall metadata
- rclone remote target
- encryption settings

## Rclone

Once rclone is configured, set this in `config.yml`:

```yaml
remote:
  rclone_target: google-drive:projetos/bkp
```

Actual remote name/path can be different.

## Encryption note

Recommended encryption tool: `age`.

The VPS only needs the public recipient to encrypt backups. Keep the private key somewhere safe outside the VPS as well.

## Backup script

Script:

```text
/root/ops/backups/backup.sh
```

Dry run:

```bash
/root/ops/backups/backup.sh --dry-run
```

Run local backup only, without upload:

```bash
/root/ops/backups/backup.sh --no-upload
```

Run backup and upload to the configured rclone remote:

```bash
/root/ops/backups/backup.sh
```

Run only one project:

```bash
/root/ops/backups/backup.sh --project kanban
```

The script writes:

- `manifest.json`
- `backup.log`
- `RESTORE.md`
- encrypted database dumps: `*.pgcustom.age`
- encrypted directory archives: `*.tar.zst.age`

## Restore rule

A backup is not trusted until at least one database dump and one directory archive have been restored successfully in a test location.
