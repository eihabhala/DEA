#!/usr/bin/env python3
"""
DodoHook - Professional Webhook Tunneling Solution
Copyright 2024, Camlo Technologies

A self-hosted alternative to ngrok for exposing your webhook server to the internet.
Designed specifically for trading applications and TradingView webhook integration.
Part of the AI Trading Expert ecosystem.
"""

import asyncio
import json
import logging
import socket
import ssl
import threading
import time
import uuid
from datetime import datetime
from typing import Dict, List, Optional
from urllib.parse import urlparse

import aiohttp
from aiohttp import web, ClientSession
import yaml


class TunnelConfig:
    """Configuration management for the tunnel server"""
    
    def __init__(self, config_file: str = "tunnel_config.yaml"):
        self.config_file = config_file
        self.load_config()
    
    def load_config(self):
        """Load configuration from YAML file"""
        default_config = {
            'server': {
                'host': '0.0.0.0',
                'port': 443,  # HTTPS port
                'domain': 'localhost',  # Your domain name
                'ssl_cert': 'server.crt',
                'ssl_key': 'server.key'
            },
            'tunnel': {
                'local_host': '127.0.0.1',
                'local_port': 5000,
                'auth_token': str(uuid.uuid4()),
                'max_connections': 100,
                'timeout': 30
            },
            'security': {
                'allowed_ips': [],  # Empty = allow all
                'rate_limit': 1000,  # requests per hour
                'require_auth': True
            },
            'logging': {
                'level': 'INFO',
                'file': 'tunnel_server.log'
            }
        }
        
        try:
            with open(self.config_file, 'r') as f:
                config = yaml.safe_load(f)
                # Merge with defaults
                for key in default_config:
                    if key not in config:
                        config[key] = default_config[key]
                    elif isinstance(default_config[key], dict):
                        for subkey in default_config[key]:
                            if subkey not in config[key]:
                                config[key][subkey] = default_config[key][subkey]
                self.config = config
        except FileNotFoundError:
            # Create default config file
            self.config = default_config
            self.save_config()
    
    def save_config(self):
        """Save configuration to YAML file"""
        with open(self.config_file, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False, indent=2)
    
    def get(self, section: str, key: str = None):
        """Get configuration value"""
        if key:
            return self.config.get(section, {}).get(key)
        return self.config.get(section, {})


class TunnelServer:
    """Custom tunnel server that replaces ngrok functionality"""
    
    def __init__(self, config: TunnelConfig):
        self.config = config
        self.app = web.Application()
        self.connections: Dict[str, dict] = {}
        self.request_stats = {'total': 0, 'success': 0, 'errors': 0}
        self.rate_limiter = {}
        
        # Setup logging
        logging.basicConfig(
            level=getattr(logging, config.get('logging', 'level')),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(config.get('logging', 'file')),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Setup routes
        self.setup_routes()
    
    def setup_routes(self):
        """Setup HTTP routes for the tunnel server"""
        
        # Main webhook endpoint that forwards to local server
        self.app.router.add_route('*', '/webhook', self.handle_webhook)
        self.app.router.add_route('*', '/webhook/{path:.*}', self.handle_webhook)
        
        # n8n specific endpoints
        self.app.router.add_route('*', '/webhook/n8n', self.handle_n8n_webhook)
        self.app.router.add_route('*', '/webhook/n8n/{workflow_id}', self.handle_n8n_workflow)
        
        # Automation platform endpoints
        self.app.router.add_route('*', '/webhook/zapier', self.handle_automation_webhook)
        self.app.router.add_route('*', '/webhook/make', self.handle_automation_webhook)
        self.app.router.add_route('*', '/webhook/automation/{platform}', self.handle_automation_webhook)
        
        # Management endpoints
        self.app.router.add_get('/status', self.handle_status)
        self.app.router.add_get('/health', self.handle_health)
        self.app.router.add_get('/dashboard', self.handle_dashboard)
        self.app.router.add_get('/stats', self.handle_stats)
        
        # Static files for dashboard (optional, handled in dashboard endpoint)
        # self.app.router.add_static('/', path='dashboard/', name='dashboard')
    
    async def handle_webhook(self, request: web.Request) -> web.Response:
        """Handle incoming webhook requests and forward to local server"""
        try:
            # Security checks
            if not await self.check_security(request):
                self.request_stats['errors'] += 1
                return web.Response(
                    text='Unauthorized',
                    status=401
                )
            
            # Rate limiting
            if not await self.check_rate_limit(request):
                self.request_stats['errors'] += 1
                return web.Response(
                    text='Rate limit exceeded',
                    status=429
                )
            
            # Forward request to local webhook server
            response = await self.forward_request(request)
            self.request_stats['success'] += 1
            self.request_stats['total'] += 1
            
            return response
            
        except Exception as e:
            self.logger.error(f"Error handling webhook: {str(e)}")
            self.request_stats['errors'] += 1
            self.request_stats['total'] += 1
            
            return web.Response(
                text=f'Internal server error: {str(e)}',
                status=500
            )
    
    async def forward_request(self, request: web.Request) -> web.Response:
        """Forward the request to the local webhook server"""
        local_host = self.config.get('tunnel', 'local_host')
        local_port = self.config.get('tunnel', 'local_port')
        local_url = f"http://{local_host}:{local_port}{request.path_qs}"
        
        try:
            async with ClientSession() as session:
                # Prepare request data
                headers = dict(request.headers)
                headers.pop('Host', None)  # Remove host header
                
                # Get request body
                body = None
                if request.method in ['POST', 'PUT', 'PATCH']:
                    body = await request.read()
                
                # Forward request
                async with session.request(
                    method=request.method,
                    url=local_url,
                    headers=headers,
                    data=body,
                    timeout=aiohttp.ClientTimeout(total=30)
                ) as response:
                    # Get response data
                    response_body = await response.read()
                    response_headers = dict(response.headers)
                    
                    # Remove hop-by-hop headers
                    hop_headers = ['connection', 'keep-alive', 'proxy-authenticate',
                                 'proxy-authorization', 'te', 'trailers', 'transfer-encoding',
                                 'upgrade']
                    for header in hop_headers:
                        response_headers.pop(header, None)
                    
                    self.logger.info(
                        f"Forwarded {request.method} {request.path} -> "
                        f"{response.status} ({len(response_body)} bytes)"
                    )
                    
                    return web.Response(
                        body=response_body,
                        status=response.status,
                        headers=response_headers
                    )
                    
        except asyncio.TimeoutError:
            self.logger.error(f"Timeout forwarding request to {local_url}")
            return web.Response(text='Local server timeout', status=504)
        except Exception as e:
            self.logger.error(f"Error forwarding request: {str(e)}")
            return web.Response(text='Failed to connect to local server', status=502)
    
    async def handle_n8n_webhook(self, request: web.Request) -> web.Response:
        """Handle n8n specific webhook requests with enhanced features"""
        try:
            # Add n8n specific headers and processing
            headers = dict(request.headers)
            headers['X-DodoHook-Platform'] = 'n8n'
            headers['X-DodoHook-Timestamp'] = str(time.time())
            
            # Enhanced logging for n8n workflows
            workflow_id = request.match_info.get('workflow_id', 'default')
            self.logger.info(f"n8n webhook received - Workflow: {workflow_id}")
            
            # Forward with n8n enhancements
            response = await self.forward_request(request)
            
            # Add n8n specific response headers
            response.headers['X-DodoHook-Platform'] = 'n8n'
            response.headers['X-DodoHook-Processed'] = 'true'
            
            return response
            
        except Exception as e:
            self.logger.error(f"n8n webhook error: {str(e)}")
            return web.Response(
                text=f'n8n webhook error: {str(e)}',
                status=500,
                headers={'X-DodoHook-Error': 'n8n-processing'}
            )
    
    async def handle_n8n_workflow(self, request: web.Request) -> web.Response:
        """Handle n8n workflow-specific webhooks"""
        workflow_id = request.match_info.get('workflow_id')
        
        try:
            # Log workflow-specific activity
            self.logger.info(f"n8n workflow webhook - ID: {workflow_id}")
            
            # Add workflow tracking
            headers = dict(request.headers)
            headers['X-n8n-Workflow-ID'] = workflow_id
            headers['X-DodoHook-Platform'] = 'n8n'
            
            response = await self.forward_request(request)
            response.headers['X-n8n-Workflow-ID'] = workflow_id
            
            return response
            
        except Exception as e:
            self.logger.error(f"n8n workflow {workflow_id} error: {str(e)}")
            return web.Response(
                text=f'n8n workflow error: {str(e)}',
                status=500
            )
    
    async def handle_automation_webhook(self, request: web.Request) -> web.Response:
        """Handle automation platform webhooks (Zapier, Make.com, etc.)"""
        platform = request.match_info.get('platform', 'unknown')
        
        try:
            # Platform-specific processing
            self.logger.info(f"Automation webhook from {platform}")
            
            # Add platform identification
            headers = dict(request.headers)
            headers['X-DodoHook-Platform'] = platform
            headers['X-DodoHook-Type'] = 'automation'
            
            response = await self.forward_request(request)
            response.headers['X-DodoHook-Platform'] = platform
            
            return response
            
        except Exception as e:
            self.logger.error(f"Automation platform {platform} error: {str(e)}")
            return web.Response(
                text=f'Automation webhook error: {str(e)}',
                status=500
            )
    
    async def check_security(self, request: web.Request) -> bool:
        """Check security constraints"""
        # Check allowed IPs
        allowed_ips = self.config.get('security', 'allowed_ips')
        if allowed_ips:
            client_ip = request.remote
            if client_ip not in allowed_ips:
                self.logger.warning(f"Blocked request from unauthorized IP: {client_ip}")
                return False
        
        # Check authentication token
        if self.config.get('security', 'require_auth'):
            auth_token = self.config.get('tunnel', 'auth_token')
            request_token = request.headers.get('Authorization', '').replace('Bearer ', '')
            
            if request_token != auth_token:
                self.logger.warning("Request with invalid or missing auth token")
                return False
        
        return True
    
    async def check_rate_limit(self, request: web.Request) -> bool:
        """Check rate limiting"""
        client_ip = request.remote
        current_time = time.time()
        rate_limit = self.config.get('security', 'rate_limit')
        
        if client_ip not in self.rate_limiter:
            self.rate_limiter[client_ip] = {'requests': [], 'blocked_until': 0}
        
        client_data = self.rate_limiter[client_ip]
        
        # Check if client is currently blocked
        if current_time < client_data['blocked_until']:
            return False
        
        # Clean old requests (older than 1 hour)
        client_data['requests'] = [
            req_time for req_time in client_data['requests']
            if current_time - req_time < 3600
        ]
        
        # Check rate limit
        if len(client_data['requests']) >= rate_limit:
            # Block for 1 hour
            client_data['blocked_until'] = current_time + 3600
            self.logger.warning(f"Rate limit exceeded for IP: {client_ip}")
            return False
        
        # Add current request
        client_data['requests'].append(current_time)
        return True
    
    async def handle_status(self, request: web.Request) -> web.Response:
        """Handle status endpoint"""
        status = {
            'status': 'running',
            'timestamp': datetime.now().isoformat(),
            'local_target': f"{self.config.get('tunnel', 'local_host')}:{self.config.get('tunnel', 'local_port')}",
            'public_url': f"https://{self.config.get('server', 'domain')}/webhook",
            'connections': len(self.connections),
            'stats': self.request_stats
        }
        return web.json_response(status)
    
    async def handle_health(self, request: web.Request) -> web.Response:
        """Handle health check endpoint"""
        try:
            # Check if local server is reachable
            local_host = self.config.get('tunnel', 'local_host')
            local_port = self.config.get('tunnel', 'local_port')
            
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((local_host, local_port))
            sock.close()
            
            if result == 0:
                return web.json_response({'status': 'healthy', 'local_server': 'reachable'})
            else:
                return web.json_response(
                    {'status': 'unhealthy', 'local_server': 'unreachable'},
                    status=503
                )
        except Exception as e:
            return web.json_response(
                {'status': 'error', 'message': str(e)},
                status=500
            )
    
    async def handle_dashboard(self, request: web.Request) -> web.Response:
        """Handle dashboard web interface"""
        dashboard_html = """
<!DOCTYPE html>
<html>
<head>
    <title>DodoHook Dashboard - by Camlo</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #333; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { color: white; font-size: 2.5em; margin: 0; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header .subtitle { color: #f0f0f0; font-size: 1.2em; margin: 10px 0; }
        .header .by-camlo { color: #ffd700; font-weight: bold; font-size: 1.1em; }
        .card { background: white; padding: 20px; margin: 20px 0; border-radius: 12px; box-shadow: 0 8px 16px rgba(0,0,0,0.2); }
        .status { padding: 15px; border-radius: 8px; font-weight: bold; margin: 10px 0; }
        .status.running { background: linear-gradient(135deg, #4CAF50, #45a049); color: white; }
        .status.error { background: linear-gradient(135deg, #f44336, #da190b); color: white; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .stat { text-align: center; padding: 15px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border-radius: 8px; }
        .stat-value { font-size: 2.5em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { font-size: 0.9em; opacity: 0.9; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 8px; overflow-x: auto; border-left: 4px solid #667eea; }
        .refresh-btn { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; padding: 12px 24px; border-radius: 8px; cursor: pointer; font-weight: bold; transition: transform 0.2s; }
        .refresh-btn:hover { transform: translateY(-2px); }
        .dodo-icon { font-size: 1.5em; margin-right: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><span class="dodo-icon">🦤</span>DodoHook</h1>
            <div class="subtitle">Professional Webhook Tunneling Solution</div>
            <div class="by-camlo">by Camlo Technologies</div>
        </div>
        
        <div class="card">
            <h2>Status</h2>
            <div id="status" class="status running">🟢 DodoHook Online</div>
            <p><strong>Public URL:</strong> <code id="public-url">Loading...</code></p>
            <p><strong>Local Target:</strong> <code id="local-target">Loading...</code></p>
            <button class="refresh-btn" onclick="refreshData()">🔄 Refresh</button>
        </div>
        
        <div class="card">
            <h2>📊 Statistics</h2>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value" id="total-requests">-</div>
                    <div class="stat-label">Total Requests</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="success-requests">-</div>
                    <div class="stat-label">Successful</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="error-requests">-</div>
                    <div class="stat-label">Errors</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="connections">-</div>
                    <div class="stat-label">Active Connections</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>🔧 TradingView & Automation Setup</h2>
            <p>Use these URLs in your automation platforms:</p>
            
            <h3>📊 TradingView</h3>
            <pre id="webhook-url">Loading...</pre>
            
            <h3>🔗 n8n Workflows</h3>
            <pre id="n8n-url">Loading...</pre>
            <p><strong>Workflow-specific:</strong> Add your workflow ID: <code>/webhook/n8n/your-workflow-id</code></p>
            
            <h3>⚡ Other Automation Platforms</h3>
            <pre>Zapier: https://webhook.dodohook.com/webhook/zapier
Make.com: https://webhook.dodohook.com/webhook/make
Custom: https://webhook.dodohook.com/webhook/automation/platform-name</pre>
            
            <p><strong>Example JSON message:</strong></p>
            <pre>{"action":"{{strategy.order.action}}","symbol":"{{ticker}}","price":"{{close}}","platform":"n8n"}</pre>
        </div>
        
        <div class="card">
            <h2>📋 Recent Activity</h2>
            <div id="activity-log">
                <p>Activity log will appear here...</p>
            </div>
        </div>
    </div>
    
    <script>
        async function refreshData() {
            try {
                const response = await fetch('/status');
                const data = await response.json();
                
                document.getElementById('public-url').textContent = data.public_url;
                document.getElementById('local-target').textContent = data.local_target;
                document.getElementById('webhook-url').textContent = data.public_url;
                document.getElementById('n8n-url').textContent = data.public_url.replace('/webhook', '/webhook/n8n');
                
                document.getElementById('total-requests').textContent = data.stats.total;
                document.getElementById('success-requests').textContent = data.stats.success;
                document.getElementById('error-requests').textContent = data.stats.errors;
                document.getElementById('connections').textContent = data.connections;
                
                const status = document.getElementById('status');
                status.className = 'status running';
                status.textContent = '🟢 DodoHook Online';
                
            } catch (error) {
                const status = document.getElementById('status');
                status.className = 'status error';
                status.textContent = '🔴 DodoHook Connection Error';
            }
        }
        
        // Auto refresh every 30 seconds
        setInterval(refreshData, 30000);
        
        // Initial load
        refreshData();
    </script>
</body>
</html>
        """
        return web.Response(text=dashboard_html, content_type='text/html')
    
    async def handle_stats(self, request: web.Request) -> web.Response:
        """Handle statistics endpoint"""
        stats = {
            'requests': self.request_stats,
            'connections': len(self.connections),
            'rate_limiter': {
                ip: {
                    'requests_count': len(data['requests']),
                    'blocked_until': data['blocked_until']
                }
                for ip, data in self.rate_limiter.items()
            }
        }
        return web.json_response(stats)
    
    async def start_server(self):
        """Start the tunnel server"""
        host = self.config.get('server', 'host')
        port = self.config.get('server', 'port')
        
        self.logger.info(f"Starting custom tunnel server on {host}:{port}")
        
        # Create SSL context if certificates are available
        ssl_context = None
        cert_file = self.config.get('server', 'ssl_cert')
        key_file = self.config.get('server', 'ssl_key')
        
        if cert_file and key_file:
            try:
                ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
                ssl_context.load_cert_chain(cert_file, key_file)
                self.logger.info("SSL/TLS enabled")
            except Exception as e:
                self.logger.warning(f"Failed to load SSL certificates: {e}")
                self.logger.info("Starting without SSL/TLS")
        
        runner = web.AppRunner(self.app)
        await runner.setup()
        
        site = web.TCPSite(runner, host, port, ssl_context=ssl_context)
        await site.start()
        
        protocol = "https" if ssl_context else "http"
        domain = self.config.get('server', 'domain')
        
        self.logger.info(f"Tunnel server started!")
        self.logger.info(f"Public webhook URL: {protocol}://{domain}/webhook")
        self.logger.info(f"Dashboard: {protocol}://{domain}/dashboard")
        self.logger.info(f"Status API: {protocol}://{domain}/status")
        
        return runner


def main():
    """Main entry point"""
    print("🦤 DodoHook - Professional Webhook Tunneling Solution")
    print("by Camlo Technologies")
    print("====================================================")
    
    # Load configuration
    config = TunnelConfig()
    
    # Create and start server
    server = TunnelServer(config)
    
    async def run_server():
        runner = await server.start_server()
        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down tunnel server...")
            await runner.cleanup()
    
    # Run the server
    try:
        asyncio.run(run_server())
    except KeyboardInterrupt:
        print("Server stopped by user")
    except Exception as e:
        print(f"Server error: {e}")


if __name__ == "__main__":
    main()