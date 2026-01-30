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
docker run -it --rm \
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
  -d www.tvn-sut.info

# Stop temporary nginx
echo "🛑 Stopping temporary nginx..."
docker stop nginx-temp
docker rm nginx-temp
rm nginx-temp.conf

# Start all services with SSL
echo "🚀 Starting all services with SSL..."
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
