#!/bin/bash

# SSL Setup Script for EverShop
# Usage: ./setup-ssl.sh

set -e

echo "🔐 Setting up SSL certificates..."

PROJECT_DIR=$(pwd)

# Create directories
mkdir -p ssl /etc/letsencrypt /var/www/certbot

# Check if certificates already exist
if [ -d "/etc/letsencrypt/live/tvn-sut.info" ]; then
    echo "✅ SSL certificates already exist."
    exit 0
fi

echo "📜 Getting SSL certificate from Let's Encrypt..."

# Create temporary nginx for ACME challenge
cat > nginx-temp-ssl.conf << 'EOF'
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
            return 444;
        }
    }
}
EOF

# Start temporary nginx
docker run -d --name nginx-temp-ssl \
  -p 80:80 \
  -v /var/www/certbot:/var/www/certbot \
  -v $PROJECT_DIR/nginx-temp-ssl.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

sleep 5

# Get certificate
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

# Clean up
docker stop nginx-temp-ssl
docker rm nginx-temp-ssl
rm nginx-temp-ssl.conf

# Restart nginx with SSL
docker-compose restart nginx

echo "✅ SSL setup completed!"
echo "🔗 Access your site: https://tvn-sut.info"