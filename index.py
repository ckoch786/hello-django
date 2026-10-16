# index.py
from workers import wsgi
from myproject.wsgi import application  # Replace 'myproject' with your project name

# This binds your Django application directly to Cloudflare's built-in WSGI adapter
Default = wsgi.entrypoint(application)
