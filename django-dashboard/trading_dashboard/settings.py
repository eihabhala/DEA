"""
Django Trading Dashboard Settings
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

import os
from pathlib import Path
from decouple import config
import dj_database_url

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-me-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost').split(',')

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'corsheaders',
    'crispy_forms',
    'crispy_bootstrap5',
    'django_extensions',
]

LOCAL_APPS = [
    'ml_analytics',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'trading_dashboard.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'ml_analytics.context_processors.dashboard_context',
            ],
        },
    },
]

WSGI_APPLICATION = 'trading_dashboard.wsgi.application'
ASGI_APPLICATION = 'trading_dashboard.asgi.application'

# Database
DATABASES = {
    'default': dj_database_url.config(
        default=config('DATABASE_URL', default='sqlite:///db.sqlite3')
    )
}

# Cache configuration (using default for development)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
}

# CORS settings
CORS_ALLOWED_ORIGINS = [
    f"https://{config('DJANGO_DOMAIN', default='localhost')}",
    f"https://{config('DODOHOOK_DOMAIN', default='webhook.dodohook.com')}",
    f"https://{config('N8N_DOMAIN', default='n8n.yourtrading.com')}",
]

CORS_ALLOW_CREDENTIALS = True

# Security settings for production
if not DEBUG:
    SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=True, cast=bool)
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_HSTS_SECONDS = config('SECURE_HSTS_SECONDS', default=31536000, cast=int)
    SECURE_HSTS_INCLUDE_SUBDOMAINS = config('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=True, cast=bool)
    SECURE_HSTS_PRELOAD = config('SECURE_HSTS_PRELOAD', default=True, cast=bool)
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_BROWSER_XSS_FILTER = True
    X_FRAME_OPTIONS = 'DENY'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': config('LOG_LEVEL', default='INFO'),
            'propagate': False,
        },
        'trading_dashboard': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Celery Configuration (disabled for development)
# CELERY_BROKER_URL = config('CELERY_BROKER_URL', default='redis://localhost:6379/0')
# CELERY_RESULT_BACKEND = config('CELERY_RESULT_BACKEND', default='redis://localhost:6379/0')

# Email Configuration
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default=EMAIL_HOST_USER)

# API Keys Configuration
ALPHA_VANTAGE_API_KEY = config('ALPHA_VANTAGE_API_KEY', default='')
NEWS_API_KEY = config('NEWS_API_KEY', default='')
TWITTER_BEARER_TOKEN = config('TWITTER_BEARER_TOKEN', default='')

# Integration URLs
DODOHOOK_DOMAIN = config('DODOHOOK_DOMAIN', default='webhook.dodohook.com')
DODOHOOK_API_URL = config('DODOHOOK_API_URL', default=f'https://{DODOHOOK_DOMAIN}/api')
N8N_DOMAIN = config('N8N_DOMAIN', default='n8n.yourtrading.com')
N8N_API_URL = config('N8N_API_URL', default=f'https://{N8N_DOMAIN}/api')

# Crispy Forms
CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
CRISPY_TEMPLATE_PACK = "bootstrap5"

# Sentry (Error Tracking) - Disabled for development
# SENTRY_DSN = config('SENTRY_DSN', default='')
# if SENTRY_DSN:
#     import sentry_sdk
#     from sentry_sdk.integrations.django import DjangoIntegration
#     
#     sentry_sdk.init(
#         dsn=SENTRY_DSN,
#         integrations=[
#             DjangoIntegration(auto_enabling=True),
#         ],
#         traces_sample_rate=1.0,
#         send_default_pii=True,
#     )

# Trading Dashboard Specific Settings
TRADING_DASHBOARD = {
    'ML_MODELS_PATH': BASE_DIR / 'ml_models',
    'DATA_STORAGE_PATH': BASE_DIR / 'data',
    'CHART_CACHE_TIMEOUT': 300,  # 5 minutes
    'REAL_TIME_UPDATE_INTERVAL': 30,  # 30 seconds
    'MAX_HISTORICAL_DAYS': 365,
    'SUPPORTED_SYMBOLS': [
        'EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'USDCAD', 'USDCHF',
        'NZDUSD', 'EURJPY', 'GBPJPY', 'EURGBP', 'XAUUSD', 'XAGUSD',
        'BTCUSD', 'ETHUSD', 'SPY', 'QQQ', 'DIA'
    ],
    'RISK_LEVELS': {
        'LOW': 0.01,
        'MEDIUM': 0.02,
        'HIGH': 0.05,
    },
    'NOTIFICATION_CHANNELS': ['email', 'discord', 'telegram', 'slack'],
}

# Custom User Model (if needed)
# AUTH_USER_MODEL = 'accounts.User'

# Django Debug Toolbar (Development only) - Disabled for now
# if DEBUG:
#     INSTALLED_APPS += ['debug_toolbar']
#     MIDDLEWARE = ['debug_toolbar.middleware.DebugToolbarMiddleware'] + MIDDLEWARE
#     
#     DEBUG_TOOLBAR_CONFIG = {
#         'SHOW_TOOLBAR_CALLBACK': lambda request: True,
#     }

# Create logs directory
import os
os.makedirs(BASE_DIR / 'logs', exist_ok=True)
os.makedirs(BASE_DIR / 'data', exist_ok=True)
os.makedirs(BASE_DIR / 'ml_models', exist_ok=True)