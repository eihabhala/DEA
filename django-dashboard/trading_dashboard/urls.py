"""
Trading Dashboard URLs Configuration
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from ml_analytics import views as ml_views

urlpatterns = [
    # Admin interface
    path('admin/', admin.site.urls),
    
    # Main dashboard
    path('', ml_views.DashboardView.as_view(), name='dashboard'),
    path('dashboard/', ml_views.DashboardView.as_view(), name='dashboard_main'),
    
    # ML Analytics app
    path('analytics/', include('ml_analytics.urls')),
    
    # API endpoints
    path('api/v1/', include('ml_analytics.api_urls')),
    
    # Health check
    path('health/', ml_views.health_check, name='health_check'),
    
    # Authentication
    path('accounts/', include('django.contrib.auth.urls')),
    
    # Favicon redirect
    path('favicon.ico', RedirectView.as_view(url='/static/favicon.ico')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Admin site configuration
admin.site.site_header = "Camlo Trading Analytics"
admin.site.site_title = "Trading Dashboard Admin"
admin.site.index_title = "ML Trading Information Management"