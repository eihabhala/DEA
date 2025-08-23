# Dockerfile for Custom Webhook Tunnel Server
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements_tunnel.txt .
RUN pip install --no-cache-dir -r requirements_tunnel.txt

# Copy application files
COPY custom_tunnel_server.py .
COPY tunnel_config.yaml .
COPY generate_ssl.sh .

# Create certs directory
RUN mkdir -p certs

# Make scripts executable
RUN chmod +x generate_ssl.sh

# Expose ports
EXPOSE 443
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:443/health || exit 1

# Start command
CMD ["python3", "custom_tunnel_server.py"]