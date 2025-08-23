"""
ML Analytics App Configuration
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.apps import AppConfig


class MlAnalyticsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ml_analytics'
    verbose_name = 'ML Analytics'
    
    def ready(self):
        """Called when the app is ready."""
        # Import signals
        try:
            import ml_analytics.signals
        except ImportError:
            pass