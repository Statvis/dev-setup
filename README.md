# dev-setup
A bash script for getting a fresh macOS install ready for Statvis development.

Installs: Homebrew, Claude Code, mise, Ruby 3.3.2, Node 20.14.0, PostgreSQL 17 + PostGIS + pgvector, Redis, OpenSearch, MinIO, and all required system dependencies. Clones the Statvis repo and sets up the database.

## Usage:
Open a terminal, enter this command:
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Statvis/dev-setup/main/setup.sh)"`

Note: keep an eye on your terminal while it runs; there are a few spots where you will be prompted to continue. For the github login, use the defaults recommended in their prompt.