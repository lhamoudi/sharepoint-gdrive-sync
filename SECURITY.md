# Security Policy

## Important: These scripts do not handle credentials

The sync scripts in this repository do not process, store, or transmit any credentials themselves. They use `rsync` and standard `git` commands to move files between directories.

## What NOT to commit to this repository

**Never commit:**
- API keys, client IDs, or client secrets
- OAuth tokens or refresh tokens
- `.env` files or any file containing secrets
- Postman collections with embedded credentials
- SSH private keys or certificates

The `.gitignore` in this repository is configured to block the most common credential file types, but it is not exhaustive. Review files before committing.

## Reporting a vulnerability

If you discover a security issue in these scripts, please open an issue in this repository describing the problem. For sensitive disclosures, contact the maintainer directly via GitHub.
