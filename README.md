# Django on Cloudflare Workers

Use [uv](https://docs.astral.sh/uv/) and Pywrangler to bundle the Python dependencies:

```sh
uv run pywrangler dev
uv run pywrangler deploy
```

The dependencies are declared in `pyproject.toml`. Deploy with Pywrangler rather than bare
`wrangler deploy` so the Python packages are included in the Worker.
