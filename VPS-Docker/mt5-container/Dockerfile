# MetaTrader 5 Docker Container
# Optimized for VPS deployment with AI Trading Expert Advisor

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Set MetaTrader user
ENV MT_USER=mt5
ENV MT_HOME=/home/${MT_USER}

# Install system dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
    # Wine dependencies (both 32-bit and 64-bit)
    wine \
    winetricks \
    # X11 and VNC
    xvfb \
    x11vnc \
    fluxbox \
    # VNC password utility
    tightvncserver \
    # Networking and utilities
    wget \
    curl \
    unzip \
    supervisor \
    # Monitoring tools
    htop \
    procps \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create MetaTrader user
RUN useradd -m -s /bin/bash ${MT_USER} \
    && usermod -aG audio,video ${MT_USER}

# Switch to MT user
USER ${MT_USER}
WORKDIR ${MT_HOME}

# Create necessary directories
RUN mkdir -p \
    "${MT_HOME}/.wine/drive_c/Program Files/MetaTrader 5" \
    "${MT_HOME}/config" \
    "${MT_HOME}/logs" \
    "${MT_HOME}/scripts"

# Download and install MetaTrader 5
RUN cd /tmp \
    && wget -q "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe" \
    && wine mt5setup.exe /S \
    && rm mt5setup.exe

# Copy configuration scripts
COPY --chown=${MT_USER}:${MT_USER} scripts/ ${MT_HOME}/scripts/
COPY --chown=${MT_USER}:${MT_USER} config/ ${MT_HOME}/config/

# Copy EA files
COPY --chown=${MT_USER}:${MT_USER} MQL5/ /home/mt5/mt5-mql/

# Make scripts executable
RUN chmod +x ${MT_HOME}/scripts/*.sh

# Switch back to root for supervisor
USER root

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create VNC password file
RUN mkdir -p /home/${MT_USER}/.vnc \
    && echo "trading123" | vncpasswd -f > /home/${MT_USER}/.vnc/passwd \
    && chmod 600 /home/${MT_USER}/.vnc/passwd \
    && chown -R ${MT_USER}:${MT_USER} /home/${MT_USER}/.vnc

# Expose VNC port
EXPOSE 5901

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "terminal64.exe" > /dev/null || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]