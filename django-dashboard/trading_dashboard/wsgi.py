"""
WSGI config for trading_dashboard project.
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'trading_dashboard.settings')

application = get_wsgi_application()