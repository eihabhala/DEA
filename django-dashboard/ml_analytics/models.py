"""
ML Analytics Models
Professional ML Trading Information Display Platform
by Camlo Technologies
"""

from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import json

class TradingSymbol(models.Model):
    """Trading symbols supported by the platform"""
    symbol = models.CharField(max_length=20, unique=True)
    name = models.CharField(max_length=100)
    category = models.CharField(max_length=50, choices=[
        ('forex', 'Forex'),
        ('crypto', 'Cryptocurrency'),
        ('stocks', 'Stocks'),
        ('commodities', 'Commodities'),
        ('indices', 'Indices'),
    ])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['symbol']
    
    def __str__(self):
        return f"{self.symbol} - {self.name}"

class MarketData(models.Model):
    """Real-time and historical market data"""
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    timestamp = models.DateTimeField()
    open_price = models.DecimalField(max_digits=15, decimal_places=6)
    high_price = models.DecimalField(max_digits=15, decimal_places=6)
    low_price = models.DecimalField(max_digits=15, decimal_places=6)
    close_price = models.DecimalField(max_digits=15, decimal_places=6)
    volume = models.BigIntegerField(default=0)
    spread = models.DecimalField(max_digits=8, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        unique_together = ['symbol', 'timestamp']
        indexes = [
            models.Index(fields=['symbol', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]
    
    def __str__(self):
        return f"{self.symbol.symbol} - {self.timestamp} - {self.close_price}"

class MLPrediction(models.Model):
    """ML model predictions for trading symbols"""
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    model_name = models.CharField(max_length=100)
    model_version = models.CharField(max_length=50)
    prediction_type = models.CharField(max_length=50, choices=[
        ('price', 'Price Prediction'),
        ('direction', 'Direction Prediction'),
        ('volatility', 'Volatility Prediction'),
        ('support_resistance', 'Support/Resistance'),
    ])
    predicted_value = models.JSONField()  # Flexible prediction data
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4)
    prediction_horizon = models.CharField(max_length=20)  # 1h, 4h, 1d, etc.
    features_used = models.JSONField()  # Features used for prediction
    timestamp = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['symbol', 'prediction_type', 'timestamp']),
            models.Index(fields=['model_name', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.symbol.symbol} - {self.model_name} - {self.prediction_type}"

class SentimentData(models.Model):
    """News and social media sentiment analysis"""
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE, null=True, blank=True)
    source = models.CharField(max_length=50, choices=[
        ('news', 'News Articles'),
        ('twitter', 'Twitter'),
        ('reddit', 'Reddit'),
        ('telegram', 'Telegram'),
        ('discord', 'Discord'),
    ])
    content = models.TextField()
    sentiment_score = models.DecimalField(max_digits=5, decimal_places=4)  # -1 to 1
    sentiment_label = models.CharField(max_length=20, choices=[
        ('positive', 'Positive'),
        ('negative', 'Negative'),
        ('neutral', 'Neutral'),
    ])
    confidence = models.DecimalField(max_digits=5, decimal_places=4)
    keywords = models.JSONField(default=list)
    url = models.URLField(null=True, blank=True)
    author = models.CharField(max_length=200, null=True, blank=True)
    published_at = models.DateTimeField()
    processed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-published_at']
        indexes = [
            models.Index(fields=['symbol', 'source', 'published_at']),
            models.Index(fields=['sentiment_label', 'published_at']),
        ]
    
    def __str__(self):
        return f"{self.source} - {self.sentiment_label} - {self.published_at}"

class TradingSignal(models.Model):
    """Trading signals from various sources"""
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    source = models.CharField(max_length=50, choices=[
        ('tradingview', 'TradingView'),
        ('ml_model', 'ML Model'),
        ('technical_analysis', 'Technical Analysis'),
        ('fundamental_analysis', 'Fundamental Analysis'),
        ('dodohook', 'DodoHook'),
        ('n8n', 'n8n Workflow'),
    ])
    signal_type = models.CharField(max_length=20, choices=[
        ('BUY', 'Buy'),
        ('SELL', 'Sell'),
        ('HOLD', 'Hold'),
        ('CLOSE', 'Close'),
    ])
    entry_price = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    stop_loss = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    take_profit = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    confidence = models.DecimalField(max_digits=5, decimal_places=4)
    risk_score = models.DecimalField(max_digits=5, decimal_places=4)
    timeframe = models.CharField(max_length=10)
    strategy_name = models.CharField(max_length=100, null=True, blank=True)
    metadata = models.JSONField(default=dict)
    is_executed = models.BooleanField(default=False)
    execution_price = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    execution_time = models.DateTimeField(null=True, blank=True)
    profit_loss = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['symbol', 'signal_type', 'created_at']),
            models.Index(fields=['source', 'created_at']),
            models.Index(fields=['is_executed', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.symbol.symbol} - {self.signal_type} - {self.source}"

class TechnicalIndicator(models.Model):
    """Technical indicators calculated for symbols"""
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    indicator_name = models.CharField(max_length=50)
    timeframe = models.CharField(max_length=10)
    value = models.JSONField()  # Can store single value or multiple values
    parameters = models.JSONField(default=dict)  # Indicator parameters
    timestamp = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        unique_together = ['symbol', 'indicator_name', 'timeframe', 'timestamp']
        indexes = [
            models.Index(fields=['symbol', 'indicator_name', 'timeframe', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.symbol.symbol} - {self.indicator_name} - {self.timeframe}"

class Portfolio(models.Model):
    """User portfolios for tracking performance"""
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    initial_balance = models.DecimalField(max_digits=15, decimal_places=2)
    current_balance = models.DecimalField(max_digits=15, decimal_places=2)
    total_pnl = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total_trades = models.IntegerField(default=0)
    winning_trades = models.IntegerField(default=0)
    max_drawdown = models.DecimalField(max_digits=5, decimal_places=4, default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.name}"
    
    @property
    def win_rate(self):
        if self.total_trades == 0:
            return 0
        return (self.winning_trades / self.total_trades) * 100

class Trade(models.Model):
    """Individual trades executed"""
    portfolio = models.ForeignKey(Portfolio, on_delete=models.CASCADE)
    signal = models.ForeignKey(TradingSignal, on_delete=models.SET_NULL, null=True, blank=True)
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    trade_type = models.CharField(max_length=20, choices=[
        ('BUY', 'Buy'),
        ('SELL', 'Sell'),
    ])
    entry_price = models.DecimalField(max_digits=15, decimal_places=6)
    exit_price = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    quantity = models.DecimalField(max_digits=15, decimal_places=6)
    stop_loss = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    take_profit = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    profit_loss = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)
    commission = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_open = models.BooleanField(default=True)
    entry_time = models.DateTimeField()
    exit_time = models.DateTimeField(null=True, blank=True)
    strategy = models.CharField(max_length=100, null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-entry_time']
        indexes = [
            models.Index(fields=['portfolio', 'symbol', 'entry_time']),
            models.Index(fields=['is_open', 'entry_time']),
        ]
    
    def __str__(self):
        return f"{self.symbol.symbol} - {self.trade_type} - {self.entry_time}"

class RiskMetrics(models.Model):
    """Risk metrics calculated for portfolios"""
    portfolio = models.ForeignKey(Portfolio, on_delete=models.CASCADE)
    var_1d = models.DecimalField(max_digits=15, decimal_places=6)  # Value at Risk 1 day
    var_5d = models.DecimalField(max_digits=15, decimal_places=6)  # Value at Risk 5 days
    sharpe_ratio = models.DecimalField(max_digits=8, decimal_places=4)
    sortino_ratio = models.DecimalField(max_digits=8, decimal_places=4)
    max_drawdown = models.DecimalField(max_digits=5, decimal_places=4)
    volatility = models.DecimalField(max_digits=8, decimal_places=4)
    beta = models.DecimalField(max_digits=8, decimal_places=4, null=True, blank=True)
    alpha = models.DecimalField(max_digits=8, decimal_places=4, null=True, blank=True)
    correlation_spy = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    calculated_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-calculated_at']
        indexes = [
            models.Index(fields=['portfolio', 'calculated_at']),
        ]
    
    def __str__(self):
        return f"{self.portfolio.name} - Risk Metrics - {self.calculated_at}"

class ModelPerformance(models.Model):
    """ML model performance tracking"""
    model_name = models.CharField(max_length=100)
    model_version = models.CharField(max_length=50)
    symbol = models.ForeignKey(TradingSymbol, on_delete=models.CASCADE)
    prediction_type = models.CharField(max_length=50)
    accuracy = models.DecimalField(max_digits=5, decimal_places=4)
    precision = models.DecimalField(max_digits=5, decimal_places=4)
    recall = models.DecimalField(max_digits=5, decimal_places=4)
    f1_score = models.DecimalField(max_digits=5, decimal_places=4)
    mae = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)  # Mean Absolute Error
    rmse = models.DecimalField(max_digits=15, decimal_places=6, null=True, blank=True)  # Root Mean Square Error
    total_predictions = models.IntegerField()
    correct_predictions = models.IntegerField()
    evaluation_period_start = models.DateTimeField()
    evaluation_period_end = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['model_name', 'symbol', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.model_name} - {self.symbol.symbol} - {self.accuracy}"