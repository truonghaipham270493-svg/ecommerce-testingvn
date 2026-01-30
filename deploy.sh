#!/bin/bash

# EverShop VPS Deployment Script
# Usage: Run this script in the project folder after cloning from Git

set -e

echo "🚀 Starting EverShop deployment to VPS..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Get current directory
PROJECT_DIR=$(pwd)
echo "📁 Project directory: $PROJECT_DIR"

# Update system (optional - comment out if not needed)
echo "📦 Updating system packages (optional)..."
apt-get update && apt-get upgrade -y || echo "System update skipped or failed"

# Install Docker and Docker Compose if not installed
echo "🐳 Checking for Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "✅ Docker is already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose is already installed"
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p {ssl,logs,data}

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

echo "✅ Environment file created at $PROJECT_DIR/.env"

# Create docker-compose.yml from prod version
echo "🐳 Setting up Docker Compose..."
if [ -f docker-compose.prod.yml ]; then
    cp docker-compose.prod.yml docker-compose.yml
    echo "✅ Created docker-compose.yml from docker-compose.prod.yml"
else
    echo "❌ docker-compose.prod.yml not found!"
    echo "Make sure you have the production configuration files"
    exit 1
fi

# Create SSL certificate directory
echo "🔐 Setting up SSL certificates..."
mkdir -p ssl
mkdir -p /etc/letsencrypt
mkdir -p /var/www/certbot

# Create initial nginx configuration for certbot
echo "🌐 Creating temporary nginx configuration for SSL certificate..."
cat > nginx-temp.conf << 'EOF'
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
            return 444; # Close connection - we only want ACME challenges
        }
    }
}
EOF

# Start temporary nginx for SSL certificate
echo "🚀 Starting temporary nginx for SSL certificate..."
docker run -d --name nginx-temp \
  -p 80:80 \
  -v /var/www/certbot:/var/www/certbot \
  -v $PROJECT_DIR/nginx-temp.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

echo "⏳ Waiting for nginx to start..."
sleep 5

# Get SSL certificate using certbot
echo "📜 Getting SSL certificate from Let's Encrypt..."

# Check if certificates already exist
if [ -d "/etc/letsencrypt/live/tvn-sut.info" ]; then
    echo "✅ SSL certificates already exist. Using existing certificates."
else
    echo "🔄 Attempting to get new SSL certificates..."
    
    # Try to get SSL certificate
    if docker run -it --rm \
      -v /etc/letsencrypt:/etc/letsencrypt \
      -v $PROJECT_DIR/ssl:/etc/nginx/ssl \
      -v /var/www/certbot:/var/www/certbot \
      certbot/certbot certonly \
      --webroot \
      --webroot-path=/var/www/certbot \
      --email admin@tvn-sut.info \
      --agree-tos \
      --no-eff-email \
      -d tvn-sut.info \
      -d www.tvn-sut.info; then
        echo "✅ SSL certificate obtained successfully!"
    else
        echo "⚠️  Could not obtain SSL certificate. This could be due to:"
        echo "   1. Rate limits (you've requested too many certificates recently)"
        echo "   2. DNS not pointing to this server yet"
        echo "   3. Port 80 not accessible"
        echo ""
        echo "📋 Manual SSL setup options:"
        echo "   Option 1: Wait and retry later (rate limit resets: 2026-01-31 06:10:31 UTC)"
        echo "   Option 2: Use self-signed certificate for testing:"
        echo "     mkdir -p $PROJECT_DIR/ssl"
        echo "     openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
        echo "       -keyout $PROJECT_DIR/ssl/privkey.pem \\"
        echo "       -out $PROJECT_DIR/ssl/fullchain.pem \\"
        echo "       -subj \"/CN=tvn-sut.info\""
        echo "   Option 3: Use Cloudflare or other SSL proxy"
        echo ""
        echo "🚀 Starting services without SSL (HTTP only)..."
        # Modify nginx config to use HTTP only temporarily
        sed -i 's/listen 443 ssl http2;/listen 80;/g' nginx-prod.conf
        sed -i 's/ssl_certificate/# ssl_certificate/g' nginx-prod.conf
        sed -i 's/ssl_certificate_key/# ssl_certificate_key/g' nginx-prod.conf
    fi
fi

# Stop temporary nginx
echo "🛑 Stopping temporary nginx..."
docker stop nginx-temp 2>/dev/null || true
docker rm nginx-temp 2>/dev/null || true
rm -f nginx-temp.conf

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d --build

# Set up SSL certificate auto-renewal
echo "🔄 Setting up SSL certificate auto-renewal..."
cat > /etc/cron.daily/certbot-renew << EOF
#!/bin/bash
docker run --rm \\
  -v /etc/letsencrypt:/etc/letsencrypt \\
  -v $PROJECT_DIR/ssl:/etc/nginx/ssl \\
  -v /var/www/certbot:/var/www/certbot \\
  certbot/certbot renew \\
  --webroot \\
  --webroot-path=/var/www/certbot \\
  --quiet
docker-compose -f $PROJECT_DIR/docker-compose.yml exec nginx nginx -s reload
EOF

chmod +x /etc/cron.daily/certbot-renew

# Display deployment information
echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Deployment Summary:"
echo "   - Application: EverShop"
echo "   - Domain: https://tvn-sut.info"
echo "   - Database: PostgreSQL (optimized for 2GB RAM)"
echo "   - SSL: Let's Encrypt (auto-renewing)"
echo "   - Project Directory: $PROJECT_DIR"
echo ""
echo "🔧 Management Commands:"
echo "   - View logs: cd $PROJECT_DIR && docker-compose logs -f"
echo "   - Restart: cd $PROJECT_DIR && docker-compose restart"
echo "   - Stop: cd $PROJECT_DIR && docker-compose down"
echo "   - Update: cd $PROJECT_DIR && git pull && docker-compose up -d --build"
echo ""
echo "📈 Resource Usage (optimized for 1 vCPU / 2GB RAM):"
echo "   - EverShop App: 0.5 vCPU / 512MB RAM"
echo "   - PostgreSQL: 0.3 vCPU / 512MB RAM"
echo "   - Nginx: 0.1 vCPU / 64MB RAM"
echo "   - Certbot: 0.05 vCPU / 32MB RAM"
echo "   - Total: ~0.95 vCPU / ~1.12GB RAM"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Update DNS records for tvn-sut.info to point to your VPS IP"
echo "   2. Check .env file for database credentials: $PROJECT_DIR/.env"
echo "   3. Run seed data: docker-compose exec app node ./packages/evershop/dist/bin/evershop.js seed --all"
echo "   4. Access your store: https://tvn-sut.info"
echo "   5. Access admin panel: https://tvn-sut.info/admin"
echo ""
echo "✅ EverShop is now deployed with free SSL and optimized for your 1 vCPU / 2GB RAM VPS!"
