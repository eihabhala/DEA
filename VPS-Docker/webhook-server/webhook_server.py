#!/usr/bin/env python3
"""
AI Trading Expert - Webhook Server
Copyright 2024, AI Trading Team

This server receives webhook signals from TradingView and other platforms
and communicates with the MetaTrader Expert Advisor.
"""

import json
import logging
import socket
import threading
import time
from datetime import datetime
from flask import Flask, request, jsonify
from queue import Queue
import requests

class WebhookServer:
    def __init__(self, port=5000, mt_port=8081):  # Changed default port to 5000
        self.app = Flask(__name__)
        self.port = port
        self.mt_port = mt_port
        self.signal_queue = Queue()
        self.is_running = False
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('webhook_server.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Setup routes
        self.setup_routes()
        
    def setup_routes(self):
        """Setup Flask routes"""
        
        @self.app.route('/webhook', methods=['POST'])
        def webhook():
            try:
                data = request.get_json()
                self.logger.info(f"Received webhook: {data}")
                
                # Validate signal
                if self.validate_signal(data):
                    # Add to queue for processing
                    self.signal_queue.put(data)
                    
                    # Send to MetaTrader
                    if self.send_to_mt(data):
                        return jsonify({"status": "success", "message": "Signal processed"})
                    else:
                        return jsonify({"status": "error", "message": "Failed to send to MT"}), 500
                else:
                    return jsonify({"status": "error", "message": "Invalid signal"}), 400
                    
            except Exception as e:
                self.logger.error(f"Webhook error: {str(e)}")
                return jsonify({"status": "error", "message": str(e)}), 500
        
        @self.app.route('/status', methods=['GET'])
        def status():
            return jsonify({
                "status": "running",
                "queue_size": self.signal_queue.qsize(),
                "timestamp": datetime.now().isoformat()
            })
        
        @self.app.route('/health', methods=['GET'])
        def health():
            return jsonify({"status": "healthy"})
    
    def validate_signal(self, data):
        """Validate incoming signal data"""
        required_fields = ['action', 'symbol']
        
        if not isinstance(data, dict):
            return False
            
        for field in required_fields:
            if field not in data:
                self.logger.warning(f"Missing required field: {field}")
                return False
        
        valid_actions = ['BUY', 'SELL', 'CLOSE', 'CLOSE_ALL']
        if data['action'] not in valid_actions:
            self.logger.warning(f"Invalid action: {data['action']}")
            return False
            
        return True
    
    def send_to_mt(self, signal):
        """Send signal to MetaTrader via socket or file"""
        try:
            # Method 1: Try socket communication
            if self.send_via_socket(signal):
                return True
            
            # Method 2: Fallback to file communication
            return self.send_via_file(signal)
            
        except Exception as e:
            self.logger.error(f"Failed to send to MT: {str(e)}")
            return False
    
    def send_via_socket(self, signal):
        """Send signal via socket to MetaTrader"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect(('localhost', self.mt_port))
            
            message = json.dumps(signal) + '\n'
            sock.send(message.encode('utf-8'))
            
            response = sock.recv(1024).decode('utf-8')
            sock.close()
            
            self.logger.info(f"Signal sent via socket: {response}")
            return True
            
        except Exception as e:
            self.logger.debug(f"Socket communication failed: {str(e)}")
            return False
    
    def send_via_file(self, signal):
        """Send signal via file to MetaTrader"""
        try:
            signal_file = "mt_signals.json"
            
            # Read existing signals
            existing_signals = []
            try:
                with open(signal_file, 'r') as f:
                    existing_signals = json.load(f)
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            
            # Add timestamp and append new signal
            signal['timestamp'] = datetime.now().isoformat()
            signal['processed'] = False
            existing_signals.append(signal)
            
            # Keep only last 100 signals
            if len(existing_signals) > 100:
                existing_signals = existing_signals[-100:]
            
            # Write back to file
            with open(signal_file, 'w') as f:
                json.dump(existing_signals, f, indent=2)
            
            self.logger.info(f"Signal saved to file: {signal_file}")
            return True
            
        except Exception as e:
            self.logger.error(f"File communication failed: {str(e)}")
            return False
    
    def run(self):
        """Start the webhook server"""
        self.is_running = True
        self.logger.info(f"Starting webhook server on port {self.port}")
        
        # Start signal processor thread
        processor_thread = threading.Thread(target=self.process_signals)
        processor_thread.daemon = True
        processor_thread.start()
        
        # Start Flask app
        self.app.run(host='0.0.0.0', port=self.port, debug=False, use_reloader=False)
    
    def process_signals(self):
        """Background thread to process signals"""
        while self.is_running:
            try:
                if not self.signal_queue.empty():
                    signal = self.signal_queue.get(timeout=1)
                    self.logger.info(f"Processing signal: {signal}")
                    
                    # Add any signal processing logic here
                    # For example, risk validation, signal filtering, etc.
                    
                time.sleep(0.1)
                
            except Exception as e:
                self.logger.error(f"Signal processing error: {str(e)}")
                time.sleep(1)

def main():
    """Main entry point"""
    server = WebhookServer(port=5000, mt_port=8081)
    
    try:
        server.run()
    except KeyboardInterrupt:
        print("\nShutting down webhook server...")
        server.is_running = False

if __name__ == "__main__":
    main()