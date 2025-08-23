"""
ML Analytics Admin Configuration
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
import json

from .models import (
    TradingSymbol, MarketData, MLPrediction, SentimentData,
    TradingSignal, TechnicalIndicator, Portfolio, Trade,
    RiskMetrics, ModelPerformance
)


@admin.register(TradingSymbol)
class TradingSymbolAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'name', 'category', 'is_active', 'created_at']
    list_filter = ['category', 'is_active']
    search_fields = ['symbol', 'name']
    ordering = ['symbol']


@admin.register(MarketData)
class MarketDataAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'timestamp', 'close_price', 'volume', 'spread']
    list_filter = ['symbol', 'timestamp']
    search_fields = ['symbol__symbol']
    date_hierarchy = 'timestamp'
    ordering = ['-timestamp']
    readonly_fields = ['created_at']


@admin.register(MLPrediction)
class MLPredictionAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'model_name', 'prediction_type', 'confidence_score', 'timestamp']
    list_filter = ['model_name', 'prediction_type', 'symbol']
    search_fields = ['symbol__symbol', 'model_name']
    date_hierarchy = 'timestamp'
    ordering = ['-timestamp']
    readonly_fields = ['created_at']
    
    def formatted_prediction(self, obj):
        """Format prediction value for display"""
        try:
            if isinstance(obj.predicted_value, dict):
                return format_html('<pre>{}</pre>', json.dumps(obj.predicted_value, indent=2))
            return str(obj.predicted_value)
        except:
            return str(obj.predicted_value)
    formatted_prediction.short_description = 'Predicted Value'


@admin.register(SentimentData)
class SentimentDataAdmin(admin.ModelAdmin):
    list_display = ['source', 'sentiment_label', 'sentiment_score', 'symbol', 'published_at']
    list_filter = ['source', 'sentiment_label', 'symbol']
    search_fields = ['content', 'author']
    date_hierarchy = 'published_at'
    ordering = ['-published_at']
    readonly_fields = ['processed_at']
    
    def short_content(self, obj):
        """Display shortened content"""
        return obj.content[:100] + '...' if len(obj.content) > 100 else obj.content
    short_content.short_description = 'Content Preview'


@admin.register(TradingSignal)
class TradingSignalAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'signal_type', 'source', 'confidence', 'is_executed', 'created_at']
    list_filter = ['signal_type', 'source', 'is_executed', 'symbol']
    search_fields = ['symbol__symbol', 'strategy_name']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    def confidence_percentage(self, obj):
        """Display confidence as percentage"""
        return f"{float(obj.confidence) * 100:.2f}%"
    confidence_percentage.short_description = 'Confidence %'


@admin.register(TechnicalIndicator)
class TechnicalIndicatorAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'indicator_name', 'timeframe', 'timestamp']
    list_filter = ['indicator_name', 'timeframe', 'symbol']
    search_fields = ['symbol__symbol', 'indicator_name']
    date_hierarchy = 'timestamp'
    ordering = ['-timestamp']
    readonly_fields = ['created_at']


@admin.register(Portfolio)
class PortfolioAdmin(admin.ModelAdmin):
    list_display = ['user', 'name', 'current_balance', 'total_pnl', 'win_rate_display', 'is_active']
    list_filter = ['is_active', 'created_at']
    search_fields = ['user__username', 'name']
    readonly_fields = ['created_at', 'updated_at']
    
    def win_rate_display(self, obj):
        """Display win rate as percentage"""
        return f"{obj.win_rate:.2f}%" if obj.win_rate else "0.00%"
    win_rate_display.short_description = 'Win Rate'


@admin.register(Trade)
class TradeAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'trade_type', 'entry_price', 'exit_price', 'profit_loss', 'is_open', 'entry_time']
    list_filter = ['trade_type', 'is_open', 'symbol', 'portfolio']
    search_fields = ['symbol__symbol', 'strategy']
    date_hierarchy = 'entry_time'
    ordering = ['-entry_time']
    readonly_fields = ['created_at']
    
    def profit_loss_colored(self, obj):
        """Display P&L with color coding"""
        if obj.profit_loss:
            color = 'green' if obj.profit_loss > 0 else 'red'
            return format_html(
                '<span style="color: {};">{}</span>',
                color,
                obj.profit_loss
            )
        return '-'
    profit_loss_colored.short_description = 'P&L'


@admin.register(RiskMetrics)
class RiskMetricsAdmin(admin.ModelAdmin):
    list_display = ['portfolio', 'var_1d', 'sharpe_ratio', 'max_drawdown', 'calculated_at']
    list_filter = ['portfolio', 'calculated_at']
    date_hierarchy = 'calculated_at'
    ordering = ['-calculated_at']
    readonly_fields = ['created_at']


@admin.register(ModelPerformance)
class ModelPerformanceAdmin(admin.ModelAdmin):
    list_display = ['model_name', 'symbol', 'accuracy_percentage', 'total_predictions', 'created_at']
    list_filter = ['model_name', 'symbol', 'prediction_type']
    search_fields = ['model_name', 'symbol__symbol']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    def accuracy_percentage(self, obj):
        """Display accuracy as percentage"""
        return f"{float(obj.accuracy) * 100:.2f}%"
    accuracy_percentage.short_description = 'Accuracy %'


# Customize admin site
admin.site.site_header = "Camlo Trading Analytics Admin"
admin.site.site_title = "Trading Dashboard"
admin.site.index_title = "ML Trading Information Management"