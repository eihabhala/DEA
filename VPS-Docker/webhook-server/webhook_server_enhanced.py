#!/usr/bin/env python3
"""
Enhanced Webhook Server for AI Trading Expert Advisor
VPS-Optimized with Monitoring and Advanced Features
"""

import json
import logging
import os
import socket
import threading
import time
import signal
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import redis
import psycopg2
from psycopg2.extras import RealDictCursor
import yaml
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import schedule

@dataclass
class TradingSignal:
    """Enhanced trading signal structure"""
    action: str
    symbol: str
    price: float = 0.0
    lot_size: float = 0.1
    stop_loss: float = 0.0
    take_profit: float = 0.0
    comment: str = ""
    source: str = "webhook"
    timestamp: str = ""
    processed: bool = False
    mt_platform: str = "MT5"  # MT4 or MT5
    risk_score: float = 0.0
    confidence: float = 0.0

class EnhancedWebhookServer:
    def __init__(self, config_file: str = 'config.yaml'):
        self.config = self._load_config(config_file)
        self.app = Flask(__name__)
        CORS(self.app)
        
        # Initialize components
        self._setup_logging()
        self._setup_metrics()
        self._setup_database()
        self._setup_redis()
        self._setup_routes()
        self._setup_scheduler()
        
        # Signal handling
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        
        self.is_running = True
        self.logger.info("Enhanced Webhook Server initialized")

    def _load_config(self, config_file: str) -> Dict:
        """Load configuration from YAML file"""
        default_config = {
            'server': {
                'host': '0.0.0.0',
                'port': 5000,
                'debug': False
            },
            'metatrader': {
                'mt4_port': 8081,
                'mt5_port': 8082,
                'timeout': 30
            },
            'database': {
                'host': os.getenv('POSTGRES_HOST', 'postgres'),
                'port': 5432,
                'name': os.getenv('POSTGRES_DB', 'trading_db'),
                'user': os.getenv('POSTGRES_USER', 'trader'),
                'password': os.getenv('POSTGRES_PASSWORD', 'secure_password')
            },
            'redis': {
                'host': os.getenv('REDIS_HOST', 'redis'),
                'port': 6379,
                'db': 0
            },
            'security': {
                'auth_token': os.getenv('WEBHOOK_TOKEN', ''),
                'rate_limit': 1000,
                'allowed_ips': []
            },
            'logging': {
                'level': 'INFO',
                'file': '/app/logs/webhook.log'
            }
        }
        
        try:
            if os.path.exists(config_file):
                with open(config_file, 'r') as f:
                    config = yaml.safe_load(f)
                    # Merge with defaults
                    for key, value in default_config.items():
                        if key not in config:
                            config[key] = value
                return config
        except Exception as e:
            print(f"Error loading config: {e}")
        
        return default_config

    def _setup_logging(self):
        """Setup enhanced logging"""
        log_level = getattr(logging, self.config['logging']['level'])
        log_file = self.config['logging']['file']
        
        # Create log directory
        Path(log_file).parent.mkdir(parents=True, exist_ok=True)
        
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def _setup_metrics(self):
        """Setup Prometheus metrics"""
        self.metrics = {
            'signals_total': Counter('webhook_signals_total', 'Total signals received', ['source', 'action']),
            'signals_processed': Counter('webhook_signals_processed_total', 'Total signals processed', ['status']),
            'processing_time': Histogram('webhook_processing_seconds', 'Signal processing time'),
            'active_connections': Gauge('webhook_active_connections', 'Active MT connections'),
            'mt_latency': Histogram('mt_communication_seconds', 'MT communication latency', ['platform']),
            'error_count': Counter('webhook_errors_total', 'Total errors', ['type'])
        }

    def _setup_database(self):
        """Setup PostgreSQL database connection"""
        try:
            self.db_pool = psycopg2.pool.ThreadedConnectionPool(
                1, 20,  # min, max connections
                host=self.config['database']['host'],
                port=self.config['database']['port'],
                database=self.config['database']['name'],
                user=self.config['database']['user'],
                password=self.config['database']['password']
            )
            self._init_database_schema()
            self.logger.info("Database connection established")
        except Exception as e:
            self.logger.error(f"Database connection failed: {e}")
            self.db_pool = None

    def _setup_redis(self):
        """Setup Redis connection for caching"""
        try:
            self.redis_client = redis.Redis(
                host=self.config['redis']['host'],
                port=self.config['redis']['port'],
                db=self.config['redis']['db'],
                decode_responses=True
            )
            self.redis_client.ping()
            self.logger.info("Redis connection established")
        except Exception as e:
            self.logger.error(f"Redis connection failed: {e}")
            self.redis_client = None

    def _init_database_schema(self):
        """Initialize database schema"""
        if not self.db_pool:
            return
            
        schema_sql = """
        CREATE TABLE IF NOT EXISTS trading_signals (
            id SERIAL PRIMARY KEY,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            action VARCHAR(20) NOT NULL,
            symbol VARCHAR(20) NOT NULL,
            price DECIMAL(10,5),
            lot_size DECIMAL(8,2),
            stop_loss DECIMAL(10,5),
            take_profit DECIMAL(10,5),
            comment TEXT,
            source VARCHAR(50),
            mt_platform VARCHAR(10),
            processed BOOLEAN DEFAULT FALSE,
            risk_score DECIMAL(3,2),
            confidence DECIMAL(3,2),
            processing_time_ms INTEGER,
            result TEXT
        );
        
        CREATE TABLE IF NOT EXISTS system_metrics (
            id SERIAL PRIMARY KEY,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            metric_name VARCHAR(100) NOT NULL,
            metric_value DECIMAL(10,2),
            tags JSONB
        );
        
        CREATE INDEX IF NOT EXISTS idx_signals_timestamp ON trading_signals(timestamp);
        CREATE INDEX IF NOT EXISTS idx_signals_symbol ON trading_signals(symbol);
        CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON system_metrics(timestamp);
        """
        
        try:
            conn = self.db_pool.getconn()
            with conn.cursor() as cursor:
                cursor.execute(schema_sql)
            conn.commit()
            self.db_pool.putconn(conn)
        except Exception as e:
            self.logger.error(f"Database schema initialization failed: {e}")

    def _setup_routes(self):
        """Setup Flask routes"""
        
        @self.app.route('/', methods=['GET'])
        def index():
            return render_template('dashboard.html')
        
        @self.app.route('/webhook', methods=['POST'])
        def webhook():
            start_time = time.time()
            
            try:
                # Authentication check
                if not self._authenticate_request(request):
                    return jsonify({"error": "Unauthorized"}), 401
                
                # Rate limiting
                if not self._check_rate_limit(request.remote_addr):
                    return jsonify({"error": "Rate limit exceeded"}), 429
                
                # Parse signal
                signal_data = request.get_json()
                signal = self._parse_signal(signal_data)
                
                # Metrics
                self.metrics['signals_total'].labels(
                    source=signal.source, 
                    action=signal.action
                ).inc()
                
                # Validate and enrich signal
                if not self._validate_signal(signal):
                    self.metrics['signals_processed'].labels(status='invalid').inc()
                    return jsonify({"error": "Invalid signal"}), 400
                
                # Risk assessment
                signal.risk_score = self._calculate_risk_score(signal)
                signal.confidence = self._calculate_confidence(signal)
                
                # Process signal
                result = self._process_signal(signal)
                
                # Record processing time
                processing_time = (time.time() - start_time) * 1000
                self.metrics['processing_time'].observe(time.time() - start_time)
                
                # Log to database
                self._log_signal_to_db(signal, processing_time, result)
                
                # Cache recent signals
                self._cache_signal(signal)
                
                if result['success']:
                    self.metrics['signals_processed'].labels(status='success').inc()
                    return jsonify({"status": "success", "message": result['message']})
                else:
                    self.metrics['signals_processed'].labels(status='error').inc()
                    return jsonify({"status": "error", "message": result['message']}), 500
                    
            except Exception as e:
                self.logger.error(f"Webhook error: {str(e)}")
                self.metrics['error_count'].labels(type='webhook').inc()
                return jsonify({"status": "error", "message": str(e)}), 500

        @self.app.route('/health', methods=['GET'])
        def health():
            health_status = {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "components": {
                    "database": self._check_database_health(),
                    "redis": self._check_redis_health(),
                    "mt_connections": self._check_mt_connections()
                }
            }
            return jsonify(health_status)

        @self.app.route('/metrics', methods=['GET'])
        def metrics():
            return generate_latest(), 200, {'Content-Type': 'text/plain; charset=utf-8'}

        @self.app.route('/status', methods=['GET'])
        def status():
            return jsonify({
                "server_time": datetime.now().isoformat(),
                "uptime": self._get_uptime(),
                "active_signals": self._get_active_signals_count(),
                "processed_today": self._get_signals_processed_today(),
                "system_load": self._get_system_metrics()
            })

        @self.app.route('/signals', methods=['GET'])
        def get_signals():
            limit = request.args.get('limit', 100, type=int)
            signals = self._get_recent_signals(limit)
            return jsonify(signals)

    def _authenticate_request(self, request) -> bool:
        """Authenticate incoming request"""
        auth_token = self.config['security']['auth_token']
        if not auth_token:
            return True  # No authentication required
        
        # Check Authorization header
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            return token == auth_token
        
        # Check query parameter
        token = request.args.get('token')
        return token == auth_token

    def _check_rate_limit(self, ip_address: str) -> bool:
        """Check rate limiting"""
        if not self.redis_client:
            return True
        
        key = f"rate_limit:{ip_address}"
        current = self.redis_client.get(key)
        
        if current is None:
            self.redis_client.setex(key, 60, 1)  # 1 request in 60 seconds window
            return True
        
        if int(current) >= self.config['security']['rate_limit']:
            return False
        
        self.redis_client.incr(key)
        return True

    def _parse_signal(self, data: Dict) -> TradingSignal:
        """Parse incoming signal data"""
        return TradingSignal(
            action=data.get('action', '').upper(),
            symbol=data.get('symbol', ''),
            price=float(data.get('price', 0)),
            lot_size=float(data.get('lot_size', 0.1)),
            stop_loss=float(data.get('stop_loss', 0)),
            take_profit=float(data.get('take_profit', 0)),
            comment=data.get('comment', ''),
            source=data.get('source', 'webhook'),
            timestamp=datetime.now().isoformat(),
            mt_platform=data.get('mt_platform', 'MT5')
        )

    def _validate_signal(self, signal: TradingSignal) -> bool:
        """Validate trading signal"""
        valid_actions = ['BUY', 'SELL', 'CLOSE', 'CLOSE_ALL']
        
        if signal.action not in valid_actions:
            return False
        
        if not signal.symbol:
            return False
        
        if signal.lot_size <= 0:
            return False
        
        return True

    def _calculate_risk_score(self, signal: TradingSignal) -> float:
        """Calculate risk score for signal"""
        # Simple risk scoring based on lot size and market conditions
        base_risk = min(signal.lot_size * 10, 1.0)  # Cap at 1.0
        
        # Add volatility factor (placeholder - would integrate with market data)
        volatility_factor = 0.1
        
        return min(base_risk + volatility_factor, 1.0)

    def _calculate_confidence(self, signal: TradingSignal) -> float:
        """Calculate confidence score for signal"""
        # Placeholder confidence calculation
        # In real implementation, this would use AI analysis
        base_confidence = 0.7
        
        # Adjust based on source
        if signal.source == 'TradingView':
            base_confidence += 0.1
        elif signal.source == 'AI_Analysis':
            base_confidence += 0.2
        
        return min(base_confidence, 1.0)

    def _process_signal(self, signal: TradingSignal) -> Dict:
        """Process trading signal"""
        try:
            # Determine MT platform port
            mt_port = (self.config['metatrader']['mt5_port'] 
                      if signal.mt_platform == 'MT5' 
                      else self.config['metatrader']['mt4_port'])
            
            # Try socket communication first
            if self._send_via_socket(signal, mt_port):
                return {"success": True, "message": "Signal sent via socket"}
            
            # Fallback to file communication
            if self._send_via_file(signal):
                return {"success": True, "message": "Signal sent via file"}
            
            return {"success": False, "message": "Failed to send signal"}
            
        except Exception as e:
            self.logger.error(f"Signal processing error: {e}")
            return {"success": False, "message": str(e)}

    def _send_via_socket(self, signal: TradingSignal, port: int) -> bool:
        """Send signal via socket to MetaTrader"""
        start_time = time.time()
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.config['metatrader']['timeout'])
            sock.connect(('localhost', port))
            
            message = json.dumps(asdict(signal)) + '\n'
            sock.send(message.encode('utf-8'))
            
            response = sock.recv(1024).decode('utf-8')
            sock.close()
            
            # Record latency
            latency = time.time() - start_time
            self.metrics['mt_latency'].labels(platform=signal.mt_platform).observe(latency)
            
            self.logger.info(f"Signal sent via socket to {signal.mt_platform}: {response}")
            return True
            
        except Exception as e:
            self.logger.debug(f"Socket communication failed: {e}")
            return False

    def _send_via_file(self, signal: TradingSignal) -> bool:
        """Send signal via file to MetaTrader"""
        try:
            signal_file = f"/app/data/{signal.mt_platform.lower()}_signals.json"
            
            # Read existing signals
            existing_signals = []
            try:
                if os.path.exists(signal_file):
                    with open(signal_file, 'r') as f:
                        existing_signals = json.load(f)
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            
            # Add new signal
            existing_signals.append(asdict(signal))
            
            # Keep only last 100 signals
            if len(existing_signals) > 100:
                existing_signals = existing_signals[-100:]
            
            # Write back to file
            os.makedirs(os.path.dirname(signal_file), exist_ok=True)
            with open(signal_file, 'w') as f:
                json.dump(existing_signals, f, indent=2)
            
            self.logger.info(f"Signal saved to file: {signal_file}")
            return True
            
        except Exception as e:
            self.logger.error(f"File communication failed: {e}")
            return False

    def _setup_scheduler(self):
        """Setup background tasks scheduler"""
        schedule.every(5).minutes.do(self._cleanup_old_data)
        schedule.every(1).hours.do(self._update_system_metrics)
        schedule.every(1).days.do(self._generate_daily_report)
        
        # Start scheduler thread
        scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
        scheduler_thread.start()

    def _run_scheduler(self):
        """Run scheduled tasks"""
        while self.is_running:
            schedule.run_pending()
            time.sleep(60)

    def _cleanup_old_data(self):
        """Cleanup old data"""
        if self.db_pool:
            try:
                conn = self.db_pool.getconn()
                with conn.cursor() as cursor:
                    # Delete signals older than 30 days
                    cursor.execute(
                        "DELETE FROM trading_signals WHERE timestamp < %s",
                        (datetime.now() - timedelta(days=30),)
                    )
                    # Delete metrics older than 7 days
                    cursor.execute(
                        "DELETE FROM system_metrics WHERE timestamp < %s",
                        (datetime.now() - timedelta(days=7),)
                    )
                conn.commit()
                self.db_pool.putconn(conn)
                self.logger.info("Old data cleanup completed")
            except Exception as e:
                self.logger.error(f"Cleanup error: {e}")

    def _log_signal_to_db(self, signal: TradingSignal, processing_time: float, result: Dict):
        """Log signal to database"""
        if not self.db_pool:
            return
        
        try:
            conn = self.db_pool.getconn()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO trading_signals 
                    (action, symbol, price, lot_size, stop_loss, take_profit, 
                     comment, source, mt_platform, risk_score, confidence, 
                     processing_time_ms, result)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    signal.action, signal.symbol, signal.price, signal.lot_size,
                    signal.stop_loss, signal.take_profit, signal.comment,
                    signal.source, signal.mt_platform, signal.risk_score,
                    signal.confidence, processing_time, json.dumps(result)
                ))
            conn.commit()
            self.db_pool.putconn(conn)
        except Exception as e:
            self.logger.error(f"Database logging error: {e}")

    def _cache_signal(self, signal: TradingSignal):
        """Cache signal in Redis"""
        if not self.redis_client:
            return
        
        try:
            key = f"signal:{signal.timestamp}"
            self.redis_client.setex(key, 3600, json.dumps(asdict(signal)))  # 1 hour TTL
        except Exception as e:
            self.logger.error(f"Redis caching error: {e}")

    def _check_database_health(self) -> str:
        """Check database health"""
        if not self.db_pool:
            return "disconnected"
        
        try:
            conn = self.db_pool.getconn()
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
            self.db_pool.putconn(conn)
            return "healthy"
        except:
            return "unhealthy"

    def _check_redis_health(self) -> str:
        """Check Redis health"""
        if not self.redis_client:
            return "disconnected"
        
        try:
            self.redis_client.ping()
            return "healthy"
        except:
            return "unhealthy"

    def _check_mt_connections(self) -> Dict:
        """Check MetaTrader connections"""
        connections = {}
        
        for platform, port in [('MT4', self.config['metatrader']['mt4_port']), 
                              ('MT5', self.config['metatrader']['mt5_port'])]:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                connections[platform] = "connected" if result == 0 else "disconnected"
            except:
                connections[platform] = "error"
        
        return connections

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.is_running = False
        sys.exit(0)

    def run(self):
        """Start the enhanced webhook server"""
        self.logger.info(f"Starting Enhanced Webhook Server on {self.config['server']['host']}:{self.config['server']['port']}")
        
        self.app.run(
            host=self.config['server']['host'],
            port=self.config['server']['port'],
            debug=self.config['server']['debug'],
            threaded=True
        )

def main():
    """Main entry point"""
    server = EnhancedWebhookServer()
    
    try:
        server.run()
    except KeyboardInterrupt:
        print("\nShutting down Enhanced Webhook Server...")
    except Exception as e:
        print(f"Server error: {e}")

if __name__ == "__main__":
    main()