# Django on Cloudflare Workers

This project runs Django as a Python Cloudflare Worker using the Workers Python runtime,
Pywrangler, and `uv`.

## Prerequisites

- A Cloudflare account.
- Node.js and npm, for Wrangler.
- [`uv`](https://docs.astral.sh/uv/getting-started/installation/).

On Ubuntu, install `uv` with:

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Restart the terminal after installation, then verify that `uv --version` works.

## Project setup

For a new repository, add the following files and folders. Django project and app files can
be generated with `uv run django-admin startproject myproject .` and
`uv run python manage.py startapp pages`; keep the settings, routes, and WSGI entry point
consistent with the configuration described here.

| Path | Purpose |
| --- | --- |
| `pyproject.toml` | Declares Python version, Django and `tzdata` runtime dependencies, and the `workers-py` / `workers-runtime-sdk` development dependencies. |
| `wrangler.jsonc` | Names the Worker, points `main` at `index.py`, and enables the Python Workers compatibility flags. |
| `index.py` | Worker entry point; sets `DJANGO_SETTINGS_MODULE`, creates the WSGI app, and exposes it through `workers.wsgi.entrypoint`. |
| `deploy.sh` | Syncs Pyodide dependencies, moves local virtual environments out of Wrangler's scan, and deploys the Worker. |
| `.gitignore` | Excludes local environments and generated runtime state from the repository. |
| `manage.py` | Django management commands for local development, checks, and migrations. |
| `myproject/__init__.py` | Makes the Django project importable as a Python package. |
| `myproject/settings.py` | Django settings; set `DEBUG = False` and configure `ALLOWED_HOSTS` for the deployed hostname and custom domains. |
| `myproject/urls.py` | Root URL routing, including routes from the Django app. |
| `myproject/wsgi.py` | Standard Django WSGI application configuration. |
| `pages/__init__.py`, `pages/apps.py`, `pages/models.py`, `pages/views.py`, `pages/urls.py`, `pages/migrations/__init__.py` | Django app package, configuration, models, request handlers, routes, and migrations package. Add migration files, templates, and static files here as the app needs them. |
| `uv.lock` | `uv` lockfile for reproducible project and development dependencies; generate with `uv lock` and commit it. |
| `pylock.toml` | Pywrangler's Pyodide-targeted dependency lockfile; generate with `uv run pywrangler sync` and commit it. |

The generated/local paths below are not source files to copy into a new repository. Include
them in the root `.gitignore`; Pywrangler recreates `python_modules` during sync.

```text
.venv/
.venv-workers/
venv/
python_modules/
.wrangler/
```

For a new repository, preserve these configuration details:

1. Declare application packages in `pyproject.toml`. Django and `tzdata` are runtime
   dependencies. `tzdata` is needed because Pyodide does not include a timezone database.
   Declare `workers-py` and `workers-runtime-sdk` in the development dependency group.
   Do not use `requirements.txt`; Pywrangler reads dependencies from `pyproject.toml`.
2. Name the Wrangler config **`wrangler.jsonc`**. Pywrangler looks for this filename (or
   `wrangler.toml`) when syncing dependencies.
3. Set the Worker entry point to `index.py` and enable the Python Workers compatibility flags:

   ```jsonc
   {
     "name": "your-worker-name",
     "main": "index.py",
     "compatibility_date": "YYYY-MM-DD",
     "compatibility_flags": [
       "python_workers",
       "disable_python_external_sdk"
     ]
   }
   ```

4. Set `DJANGO_SETTINGS_MODULE` in `index.py`, create the WSGI application with
   `get_wsgi_application()`, and expose it with `workers.wsgi.entrypoint(application)`.
5. In Django settings, set `DEBUG = False` and add the deployed `workers.dev` hostname to
   `ALLOWED_HOSTS`. Add any custom domains there as well. An empty host list causes
   `DisallowedHost` errors on Cloudflare.
6. Ignore local environments and generated files in the repository root `.gitignore`:

   ```gitignore
   /.venv/
   /.venv-workers/
   /venv/
   /python_modules/
   /.wrangler/
   ```

   Wrangler scans Python files under the project directory, including Python environments.
   This project’s `deploy.sh` temporarily moves those environments outside its scan before
   deployment and restores them afterward. Keep the script if local virtual environments are
   stored inside the project.

## Install, run, and deploy

From the project root:

```sh
uv sync
uv run pywrangler dev
```

Deploy using the included helper, not bare `wrangler deploy` or `uv run pywrangler deploy`:

```sh
bash deploy.sh
```

The helper runs `uv run pywrangler sync` to vendor the Pyodide-compatible dependencies into
`python_modules`, then invokes Wrangler while local environments are temporarily out of the
project scan. To verify the bundle without uploading:

```sh
bash deploy.sh --dry-run
```

If Wrangler reports that the multipart upload is too large, check its dry-run output. A large
bundle can mean Python files from local virtual environments are being included; ensure
`deploy.sh` moves every environment directory in the project out of the scan.

## Troubleshooting

- **Pywrangler cannot find Wrangler config:** rename `wrangler.json` to `wrangler.jsonc`.
- **`ModuleNotFoundError: django`:** declare Django in `pyproject.toml` and deploy with the
  helper so Pywrangler syncs and includes the dependencies.
- **Multipart upload too large:** deploy with `bash deploy.sh`; local virtual environments
  must not be part of Wrangler’s Python-module scan.
- **Error 1101 / `DisallowedHost`:** add the exact deployed hostname to Django’s
  `ALLOWED_HOSTS`.
- **`ZoneInfoNotFoundError` / missing `tzdata`:** add `tzdata` to project dependencies and
  redeploy so Pywrangler vendors it.
- **View deployed logs:**

  ```sh
  uv run pywrangler tail your-worker-name
  ```
