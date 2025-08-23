"""
ML Analytics URLs Configuration
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.urls import path
from . import views

app_name = 'ml_analytics'

urlpatterns = [
    # Main dashboard views
    path('', views.DashboardView.as_view(), name='dashboard'),
    path('market-data/', views.MarketDataView.as_view(), name='market_data'),
    path('predictions/', views.MLPredictionsView.as_view(), name='ml_predictions'),
    path('sentiment/', views.SentimentAnalysisView.as_view(), name='sentiment_analysis'),
    path('signals/', views.TradingSignalsView.as_view(), name='trading_signals'),
    path('portfolio/', views.PortfolioView.as_view(), name='portfolio'),
    path('risk/', views.RiskAnalysisView.as_view(), name='risk_analysis'),
]