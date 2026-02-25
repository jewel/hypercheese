# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Hypercheese is a Ruby on Rails 7.2 photo/video organizer with a React frontend (esbuild), MariaDB database, and MinIO (S3-compatible) object storage. See `README.md` for basic setup steps.

### Services

| Service | How to start | Port |
|---------|-------------|------|
| Rails (Puma) | `bundle exec rails server -b 0.0.0.0 -p 3000` | 3000 |
| Asset watcher | `yarn watch` | N/A |
| MariaDB + MinIO | `docker compose up -d mariadb minio` | 3306, 9000/9001 |
| Background worker | `bundle exec rake jobs:work` | N/A |
| All-in-one (foreman) | `bundle exec foreman start -f Procfile.dev` | 3000 |

### Gotchas

- **rexml missing in test env**: Ruby 3.2 on Ubuntu 24.04 does not bundle `rexml` in the standard library. Bundler restricts load paths so the test group gems (`selenium-webdriver`, `webdrivers`) fail to load. Set `export RUBYOPT="-I/var/lib/gems/3.2.0/gems/rexml-3.4.4/lib"` before running test commands. This is already configured in `~/.bashrc`.
- **Database config**: `config/database.yml` is not committed. Copy from `config/database.yml.example` for SQLite, or create one pointing to the Docker MariaDB (host `127.0.0.1`, user `cheese`, password `password`, database `hypercheese_dev`). The schema uses MySQL-specific features (JSON check constraints, collations), so MariaDB is recommended.
- **Secret key**: `.secret_key_base` must exist in the project root. Generate with `bundle exec rails secret > .secret_key_base`.
- **Gem permissions**: When installing gems globally with `sudo bundle install`, ensure `/var/lib/gems/3.2.0/` has read permissions (`sudo chmod -R a+rX /var/lib/gems/3.2.0/`).
- **Bootsnap cache**: If switching between gem installation methods, clear `tmp/cache/` to avoid stale bootsnap cache errors.
- **Admin panel (Trestle)**: The `/admin` route has a pre-existing ExecJS/Sprockets compilation error with the current Trestle gem version. The main application is unaffected.
- **Default login**: After `rails db:seed`, use `admin@example.com` / `password` (or username `admin`).
- **Test failures**: 3 of 6 integration tests have pre-existing assertion mismatches (error message format differences) and S3 bucket availability in test env. These are not environment issues.

### Commands

- **Tests**: `bundle exec rails test` (run from workspace root)
- **Build assets**: `yarn build`
- **Lint**: No dedicated linter configured in this project
- **Docker containers**: `docker compose up -d mariadb minio` / `docker compose down`
