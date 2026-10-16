import os
from django.core.wsgi import get_wsgi_application
from workers import wsgi

# 1. Point Django to your settings file (replace 'myproject' with your real project folder name)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# 2. Initialize the Django WSGI application
application = get_wsgi_application()

# 3. Expose the application to Cloudflare using the wsgi module adapter
Default = wsgi.entrypoint(application)
