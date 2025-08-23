"""
ML Analytics Context Processors
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.utils import timezone
from datetime import timedelta
from .models import TradingSymbol, TradingSignal, MLPrediction, SentimentData


def dashboard_context(request):
    """Global context processor for dashboard variables"""
    now = timezone.now()
    today = now.date()
    
    return {
        'app_name': 'Camlo Trading Analytics',
        'app_version': '1.0.0',
        'company': 'Camlo Technologies',
        'current_year': now.year,
        'active_symbols_count': TradingSymbol.objects.filter(is_active=True).count(),
        'today_signals_count': TradingSignal.objects.filter(created_at__date=today).count(),
        'today_predictions_count': MLPrediction.objects.filter(timestamp__date=today).count(),
        'today_sentiment_count': SentimentData.objects.filter(published_at__date=today).count(),
    }