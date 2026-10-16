# Django on Cloudflare Workers

Use [uv](https://docs.astral.sh/uv/) and Pywrangler to bundle the Python dependencies:

```sh
uv run pywrangler dev
bash deploy.sh
```

The dependencies are declared in `pyproject.toml`. Keep the Wrangler configuration named
`wrangler.jsonc` so Pywrangler can find it. Pywrangler syncs those dependencies into
`python_modules`; `deploy.sh` then invokes Wrangler after moving local environments aside.

`deploy.sh` syncs dependencies, temporarily moves local virtual environments out of Wrangler's
module scan, then restores them after deployment. Use `bash deploy.sh --dry-run` to check the
bundle without uploading it. The root `.gitignore` keeps local environments and Pywrangler's
generated `python_modules` out of version control.

Django's `ALLOWED_HOSTS` includes the deployed `workers.dev` hostname. Add any custom domain
there before routing traffic to it. The `tzdata` dependency supplies the timezone database
that Pyodide does not include by default.


# To view the deployed logs
uv run pywrangler tail django-hello-world
