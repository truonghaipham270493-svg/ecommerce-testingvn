#!/bin/bash

# EverShop VPS Deployment Script
# Usage: ./deploy.sh

set -e

echo "🚀 Starting EverShop deployment to VPS..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker and Docker Compose
echo "🐳 Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p /opt/evershop/{ssl,logs,data}
cd /opt/evershop

# Copy project files (assuming you've uploaded them)
echo "📋 Copying project files..."
# Note: You need to upload your project files to /opt/evershop
# This includes:
# - docker-compose.prod.yml
# - Dockerfile.prod
# - nginx-prod.conf
# - Your EverShop source code

# Create environment file
echo "🔧 Creating environment configuration..."
cat > .env << EOF
# Database configuration
DB_PASSWORD=$(openssl rand -base64 32)
DB_USER=evershop
DB_NAME=evershop

# Application configuration
NODE_ENV=production
PORT=3000

# Domain configuration
DOMAIN=tvn-sut.info
EMAIL=admin@tvn-sut.info
EOF

echo "✅ Environment file created at /opt/evershop/.env"

# Create docker-compose.yml from prod version
echo "🐳 Setting up Docker Compose..."
if [ -f docker-compose.prod.yml ]; then
    cp docker-compose.prod.yml docker-compose.yml
else
    echo "❌ docker-compose.prod.yml not found!"
    echo "Please upload your project files to /opt/evershop"
    exit 1
fi

# Create SSL certificate directory
echo "🔐 Setting up SSL certificates..."
mkdir -p ssl
mkdir -p /etc/letsencrypt

# Create initial nginx configuration for certbot
echo "🌐 Setting up initial nginx for SSL certificate..."
cat > nginx-init.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name tvn-sut.info www.tvn-sut.info;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$host$request_uri;
        }
    }
}
EOF

# Start initial services to get SSL certificate
echo "🚀 Starting initial services..."
docker-compose up -d database app

echo "⏳ Waiting for services to start..."
sleep 30

# Get SSL certificate using certbot
echo "📜 Getting SSL certificate from Let's Encrypt..."
docker run -it --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /opt/evershop/ssl:/etc/nginx/ssl \
  -v /var/www/certbot:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@tvn-sut.info \
  --agree-tos \
  --no-eff-email \
  -d tvn-sut.info \
  -d www.tvn-sut.info

# Start all services
echo "🚀 Starting all services with SSL..."
docker-compose down
docker-compose up -d

# Set up SSL certificate auto-renewal
echo "🔄 Setting up SSL certificate auto-renewal..."
cat > /etc/cron.daily/certbot-renew << 'EOF'
#!/bin/bash
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /opt/evershop/ssl:/etc/nginx/ssl \
  -v /var/www/certbot:/var/www/certbot \
  certbot/certbot renew \
  --webroot \
  --webroot-path=/var/www/certbot \
  --quiet
docker-compose -f /opt/evershop/docker-compose.yml exec nginx nginx -s reload
EOF

chmod +x /etc/cron.daily/certbot-renew

# Display deployment information
echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Deployment Summary:"
echo "   - Application: EverShop"
echo "   - Domain: https://tvn-sut.info"
echo "   - Database: PostgreSQL"
echo "   - SSL: Let's Encrypt (auto-renewing)"
echo "   - Directory: /opt/evershop"
echo ""
echo "🔧 Management Commands:"
echo "   - View logs: cd /opt/evershop && docker-compose logs -f"
echo "   - Restart: cd /opt/evershop && docker-compose restart"
echo "   - Stop: cd /opt/evershop && docker-compose down"
echo "   - Update: cd /opt/evershop && docker-compose pull && docker-compose up -d"
echo ""
echo "⚠️  Important:"
echo "   1. Update DNS records for tvn-sut.info to point to your VPS IP"
echo "   2. Check .env file for database credentials"
echo "   3. Run seed data: docker-compose exec app node ./packages/evershop/dist/bin/evershop.js seed --all"
echo ""
echo "✅ EverShop is now deployed with free SSL!"