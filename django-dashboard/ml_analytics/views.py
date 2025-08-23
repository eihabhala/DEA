"""
ML Analytics Views
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse, HttpResponse
from django.views.generic import TemplateView, ListView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Q, Avg, Count, Sum
from django.utils import timezone
from datetime import timedelta, datetime
from django.core.paginator import Paginator
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

from .models import (
    TradingSymbol, MarketData, MLPrediction, SentimentData,
    TradingSignal, Portfolio, Trade, TechnicalIndicator,
    RiskMetrics, ModelPerformance
)


class DashboardView(TemplateView):
    """Main dashboard view showing ML trading information overview"""
    template_name = 'ml_analytics/dashboard.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Get current date range
        now = timezone.now()
        today = now.date()
        last_7_days = now - timedelta(days=7)
        last_30_days = now - timedelta(days=30)
        
        # Active trading symbols
        active_symbols = TradingSymbol.objects.filter(is_active=True)[:10]
        
        # Recent market data
        recent_market_data = MarketData.objects.select_related('symbol').order_by('-timestamp')[:20]
        
        # ML Predictions summary
        recent_predictions = MLPrediction.objects.select_related('symbol').order_by('-timestamp')[:10]
        prediction_accuracy = MLPrediction.objects.filter(
            timestamp__gte=last_7_days
        ).aggregate(avg_confidence=Avg('confidence_score'))
        
        # Sentiment analysis summary
        sentiment_summary = SentimentData.objects.filter(
            published_at__gte=last_7_days
        ).values('sentiment_label').annotate(count=Count('id'))
        
        # Trading signals summary
        recent_signals = TradingSignal.objects.select_related('symbol').order_by('-created_at')[:15]
        signals_by_type = TradingSignal.objects.filter(
            created_at__gte=last_7_days
        ).values('signal_type').annotate(count=Count('id'))
        
        # Portfolio performance (if user has portfolios)
        user_portfolios = []
        if self.request.user.is_authenticated:
            user_portfolios = Portfolio.objects.filter(
                user=self.request.user,
                is_active=True
            )
        
        # Risk metrics summary
        risk_summary = RiskMetrics.objects.filter(
            calculated_at__gte=last_7_days
        ).aggregate(
            avg_var=Avg('var_1d'),
            avg_sharpe=Avg('sharpe_ratio'),
            avg_drawdown=Avg('max_drawdown')
        )
        
        # Model performance summary
        model_performance = ModelPerformance.objects.filter(
            created_at__gte=last_30_days
        ).values('model_name').annotate(
            avg_accuracy=Avg('accuracy'),
            total_predictions=Sum('total_predictions')
        ).order_by('-avg_accuracy')[:5]
        
        context.update({
            'active_symbols': active_symbols,
            'recent_market_data': recent_market_data,
            'recent_predictions': recent_predictions,
            'prediction_accuracy': prediction_accuracy,
            'sentiment_summary': sentiment_summary,
            'recent_signals': recent_signals,
            'signals_by_type': signals_by_type,
            'user_portfolios': user_portfolios,
            'risk_summary': risk_summary,
            'model_performance': model_performance,
            'stats': {
                'total_symbols': TradingSymbol.objects.filter(is_active=True).count(),
                'total_predictions_today': MLPrediction.objects.filter(timestamp__date=today).count(),
                'total_signals_today': TradingSignal.objects.filter(created_at__date=today).count(),
                'total_sentiment_today': SentimentData.objects.filter(published_at__date=today).count(),
            }
        })
        
        return context


class MarketDataView(ListView):
    """Market data list and detail view"""
    model = MarketData
    template_name = 'ml_analytics/market_data.html'
    context_object_name = 'market_data'
    paginate_by = 50
    
    def get_queryset(self):
        queryset = MarketData.objects.select_related('symbol').order_by('-timestamp')
        
        # Filter by symbol if provided
        symbol = self.request.GET.get('symbol')
        if symbol:
            queryset = queryset.filter(symbol__symbol=symbol)
        
        # Filter by date range
        date_from = self.request.GET.get('date_from')
        date_to = self.request.GET.get('date_to')
        if date_from:
            queryset = queryset.filter(timestamp__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(timestamp__date__lte=date_to)
        
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['symbols'] = TradingSymbol.objects.filter(is_active=True)
        context['selected_symbol'] = self.request.GET.get('symbol', '')
        return context


class MLPredictionsView(ListView):
    """ML predictions view"""
    model = MLPrediction
    template_name = 'ml_analytics/ml_predictions.html'
    context_object_name = 'predictions'
    paginate_by = 30
    
    def get_queryset(self):
        queryset = MLPrediction.objects.select_related('symbol').order_by('-timestamp')
        
        # Filter by prediction type
        pred_type = self.request.GET.get('type')
        if pred_type:
            queryset = queryset.filter(prediction_type=pred_type)
        
        # Filter by model
        model_name = self.request.GET.get('model')
        if model_name:
            queryset = queryset.filter(model_name=model_name)
        
        # Filter by symbol
        symbol = self.request.GET.get('symbol')
        if symbol:
            queryset = queryset.filter(symbol__symbol=symbol)
        
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['prediction_types'] = MLPrediction.objects.values_list('prediction_type', flat=True).distinct()
        context['model_names'] = MLPrediction.objects.values_list('model_name', flat=True).distinct()
        context['symbols'] = TradingSymbol.objects.filter(is_active=True)
        return context


class SentimentAnalysisView(ListView):
    """Sentiment analysis view"""
    model = SentimentData
    template_name = 'ml_analytics/sentiment_analysis.html'
    context_object_name = 'sentiment_data'
    paginate_by = 50
    
    def get_queryset(self):
        queryset = SentimentData.objects.select_related('symbol').order_by('-published_at')
        
        # Filter by sentiment
        sentiment = self.request.GET.get('sentiment')
        if sentiment:
            queryset = queryset.filter(sentiment_label=sentiment)
        
        # Filter by source
        source = self.request.GET.get('source')
        if source:
            queryset = queryset.filter(source=source)
        
        # Filter by symbol
        symbol = self.request.GET.get('symbol')
        if symbol:
            queryset = queryset.filter(symbol__symbol=symbol)
        
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['sentiment_choices'] = SentimentData.objects.values_list('sentiment_label', flat=True).distinct()
        context['source_choices'] = SentimentData.objects.values_list('source', flat=True).distinct()
        context['symbols'] = TradingSymbol.objects.filter(is_active=True)
        
        # Sentiment summary
        context['sentiment_summary'] = SentimentData.objects.filter(
            published_at__gte=timezone.now() - timedelta(days=7)
        ).values('sentiment_label').annotate(count=Count('id'))
        
        return context


class TradingSignalsView(ListView):
    """Trading signals view"""
    model = TradingSignal
    template_name = 'ml_analytics/trading_signals.html'
    context_object_name = 'signals'
    paginate_by = 50
    
    def get_queryset(self):
        queryset = TradingSignal.objects.select_related('symbol').order_by('-created_at')
        
        # Filter by signal type
        signal_type = self.request.GET.get('type')
        if signal_type:
            queryset = queryset.filter(signal_type=signal_type)
        
        # Filter by source
        source = self.request.GET.get('source')
        if source:
            queryset = queryset.filter(source=source)
        
        # Filter by symbol
        symbol = self.request.GET.get('symbol')
        if symbol:
            queryset = queryset.filter(symbol__symbol=symbol)
        
        # Filter by execution status
        executed = self.request.GET.get('executed')
        if executed:
            queryset = queryset.filter(is_executed=(executed == 'true'))
        
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['signal_types'] = TradingSignal.objects.values_list('signal_type', flat=True).distinct()
        context['sources'] = TradingSignal.objects.values_list('source', flat=True).distinct()
        context['symbols'] = TradingSymbol.objects.filter(is_active=True)
        
        # Signals summary
        context['signals_summary'] = TradingSignal.objects.filter(
            created_at__gte=timezone.now() - timedelta(days=7)
        ).values('signal_type').annotate(count=Count('id'))
        
        return context


class PortfolioView(LoginRequiredMixin, ListView):
    """Portfolio management view"""
    model = Portfolio
    template_name = 'ml_analytics/portfolio.html'
    context_object_name = 'portfolios'
    
    def get_queryset(self):
        return Portfolio.objects.filter(user=self.request.user).order_by('-created_at')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Portfolio performance summary
        user_portfolios = self.get_queryset()
        if user_portfolios:
            total_balance = sum(p.current_balance for p in user_portfolios)
            total_pnl = sum(p.total_pnl for p in user_portfolios)
            avg_win_rate = sum(p.win_rate for p in user_portfolios) / len(user_portfolios)
            
            context.update({
                'total_balance': total_balance,
                'total_pnl': total_pnl,
                'avg_win_rate': avg_win_rate,
            })
        
        return context


class RiskAnalysisView(TemplateView):
    """Risk analysis and metrics view"""
    template_name = 'ml_analytics/risk_analysis.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Recent risk metrics
        recent_metrics = RiskMetrics.objects.select_related('portfolio').order_by('-calculated_at')[:20]
        
        # Risk summary
        risk_summary = RiskMetrics.objects.filter(
            calculated_at__gte=timezone.now() - timedelta(days=30)
        ).aggregate(
            avg_var_1d=Avg('var_1d'),
            avg_var_5d=Avg('var_5d'),
            avg_sharpe=Avg('sharpe_ratio'),
            avg_sortino=Avg('sortino_ratio'),
            max_drawdown=Avg('max_drawdown'),
            avg_volatility=Avg('volatility')
        )
        
        context.update({
            'recent_metrics': recent_metrics,
            'risk_summary': risk_summary,
        })
        
        return context


# API Views for real-time data
@csrf_exempt
@require_http_methods(["GET"])
def api_market_data(request):
    """API endpoint for real-time market data"""
    symbol = request.GET.get('symbol')
    limit = int(request.GET.get('limit', 100))
    
    queryset = MarketData.objects.select_related('symbol').order_by('-timestamp')
    
    if symbol:
        queryset = queryset.filter(symbol__symbol=symbol)
    
    market_data = queryset[:limit]
    
    data = []
    for item in market_data:
        data.append({
            'symbol': item.symbol.symbol,
            'timestamp': item.timestamp.isoformat(),
            'open': float(item.open_price),
            'high': float(item.high_price),
            'low': float(item.low_price),
            'close': float(item.close_price),
            'volume': item.volume,
        })
    
    return JsonResponse({'data': data})


@csrf_exempt
@require_http_methods(["GET"])
def api_sentiment_summary(request):
    """API endpoint for sentiment analysis summary"""
    days = int(request.GET.get('days', 7))
    since = timezone.now() - timedelta(days=days)
    
    sentiment_data = SentimentData.objects.filter(
        published_at__gte=since
    ).values('sentiment_label').annotate(
        count=Count('id'),
        avg_score=Avg('sentiment_score')
    )
    
    return JsonResponse({'data': list(sentiment_data)})


@csrf_exempt
@require_http_methods(["GET"])
def api_trading_signals(request):
    """API endpoint for recent trading signals"""
    limit = int(request.GET.get('limit', 50))
    
    signals = TradingSignal.objects.select_related('symbol').order_by('-created_at')[:limit]
    
    data = []
    for signal in signals:
        data.append({
            'symbol': signal.symbol.symbol,
            'signal_type': signal.signal_type,
            'source': signal.source,
            'confidence': float(signal.confidence),
            'entry_price': float(signal.entry_price) if signal.entry_price else None,
            'created_at': signal.created_at.isoformat(),
            'is_executed': signal.is_executed,
        })
    
    return JsonResponse({'data': data})


@csrf_exempt
@require_http_methods(["GET"])
def api_ml_predictions(request):
    """API endpoint for ML predictions"""
    symbol = request.GET.get('symbol')
    prediction_type = request.GET.get('type')
    limit = int(request.GET.get('limit', 50))
    
    queryset = MLPrediction.objects.select_related('symbol').order_by('-timestamp')
    
    if symbol:
        queryset = queryset.filter(symbol__symbol=symbol)
    if prediction_type:
        queryset = queryset.filter(prediction_type=prediction_type)
    
    predictions = queryset[:limit]
    
    data = []
    for pred in predictions:
        data.append({
            'symbol': pred.symbol.symbol,
            'model_name': pred.model_name,
            'prediction_type': pred.prediction_type,
            'predicted_value': pred.predicted_value,
            'confidence': float(pred.confidence_score),
            'timestamp': pred.timestamp.isoformat(),
        })
    
    return JsonResponse({'data': data})


def health_check(request):
    """Health check endpoint"""
    return HttpResponse("OK", content_type="text/plain")


def context_processor(request):
    """Global context processor for dashboard"""
    return {
        'app_name': 'Camlo Trading Analytics',
        'app_version': '1.0.0',
        'company': 'Camlo Technologies',
    }