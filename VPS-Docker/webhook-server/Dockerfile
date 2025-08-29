# Enhanced Webhook Server for AI Trading Expert Advisor
# Optimized for VPS deployment with monitoring and security

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Network utilities
    curl \
    netcat-openbsd \
    # SSL and security
    openssl \
    ca-certificates \
    # Monitoring tools
    htop \
    procps \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create app user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY *.py ./
# Note: config and templates directories will be mounted as volumes

# Create necessary directories
RUN mkdir -p /app/data /app/logs /app/backups \
    && chown -R appuser:appuser /app

# Switch to app user
USER appuser

# Expose ports
EXPOSE 5000 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Start command with proper signal handling
CMD ["python3", "webhook_server.py"]