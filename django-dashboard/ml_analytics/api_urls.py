"""
ML Analytics API URLs
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.urls import path
from . import views

app_name = 'ml_analytics_api'

urlpatterns = [
    # Real-time data API endpoints
    path('market-data/', views.api_market_data, name='api_market_data'),
    path('sentiment/', views.api_sentiment_summary, name='api_sentiment'),
    path('signals/', views.api_trading_signals, name='api_signals'),
    path('predictions/', views.api_ml_predictions, name='api_predictions'),
]