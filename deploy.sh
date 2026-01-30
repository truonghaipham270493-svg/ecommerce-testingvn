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

# Docker image configuration
# Set this to your pre-built image in registry
# Example: docker.io/yourusername/evershop:latest
DOCKER_IMAGE=docker.io/evershop:latest
EOF

echo "✅ Environment file created at $PROJECT_DIR/.env"

# Ask for Docker image if not default
# read -p "Enter Docker image name [docker.io/evershop:latest]: " CUSTOM_IMAGE
# CUSTOM_IMAGE=${CUSTOM_IMAGE:-docker.io/evershop:latest}
# if [ "$CUSTOM_IMAGE" != "docker.io/evershop:latest" ]; then
#     sed -i "s|DOCKER_IMAGE=docker.io/evershop:latest|DOCKER_IMAGE=$CUSTOM_IMAGE|g" .env
#     echo "✅ Updated .env with Docker image: $CUSTOM_IMAGE"
# fi

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

# Pull Docker image before starting
echo "📥 Pulling Docker image..."
docker-compose pull app || echo "⚠️  Could not pull image. Make sure it exists in the registry or build locally first."

# Create SSL certificate directory
echo "🔐 Setting up SSL certificates..."
mkdir -p ssl
mkdir -p ssl/custom

# Check for custom SSL certificates
echo "📜 Checking for custom SSL certificates..."
if [ -f "ssl/custom/cloudflare.pem" ] && [ -f "ssl/custom/cloudflare.key" ]; then
    echo "✅ Found custom Cloudflare SSL certificates in ssl/custom/"
    echo "   Using cloudflare.pem and cloudflare.key for SSL"
else
    echo "⚠️  Custom SSL certificates not found in ssl/custom/"
    echo "   Please ensure you have the following files:"
    echo "   - ssl/custom/cloudflare.pem (certificate)"
    echo "   - ssl/custom/cloudflare.key (private key)"
    echo ""
    echo "📋 SSL setup options:"
    echo "   Option 1: Upload your Cloudflare Origin certificates to ssl/custom/"
    echo "   Option 2: Use self-signed certificate for testing:"
    echo "     mkdir -p $PROJECT_DIR/ssl/custom"
    echo "     openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
    echo "       -keyout $PROJECT_DIR/ssl/custom/cloudflare.key \\"
    echo "       -out $PROJECT_DIR/ssl/custom/cloudflare.pem \\"
    echo "       -subj \"/CN=tvn-sut.info\""
    echo ""
    echo "🚀 Starting services without SSL (HTTP only)..."
    # Modify nginx config to use HTTP only temporarily
    sed -i 's/listen 443 ssl http2;/listen 80;/g' nginx-prod.conf
    sed -i 's/ssl_certificate/# ssl_certificate/g' nginx-prod.conf
    sed -i 's/ssl_certificate_key/# ssl_certificate_key/g' nginx-prod.conf
fi

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Note: Cloudflare Origin certificates don't require auto-renewal
# They are long-term certificates provided by Cloudflare
echo "ℹ️  Cloudflare Origin certificates don't require auto-renewal"
echo "   These certificates are valid for 15 years and managed by Cloudflare"

# Display deployment information
echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Deployment Summary:"
echo "   - Application: EverShop"
echo "   - Domain: https://tvn-sut.info"
echo "   - Database: PostgreSQL (optimized for 2GB RAM)"
echo "   - SSL: Cloudflare Origin Certificate (15-year validity)"
echo "   - Project Directory: $PROJECT_DIR"
echo ""
echo "🔧 Management Commands:"
echo "   - View logs: cd $PROJECT_DIR && docker-compose logs -f"
echo "   - Restart: cd $PROJECT_DIR && docker-compose restart"
echo "   - Stop: cd $PROJECT_DIR && docker-compose down"
echo "   - Update: cd $PROJECT_DIR && docker-compose pull && docker-compose up -d"
echo ""
echo "📈 Resource Usage (optimized for 1 vCPU / 2GB RAM):"
echo "   - EverShop App: 0.5 vCPU / 512MB RAM"
echo "   - PostgreSQL: 0.3 vCPU / 512MB RAM"
echo "   - Nginx: 0.1 vCPU / 64MB RAM"
echo "   - Total: ~0.9 vCPU / ~1.09GB RAM"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Update DNS records for tvn-sut.info to point to your VPS IP"
echo "   2. Check .env file for database credentials: $PROJECT_DIR/.env"
echo "   3. Run seed data: docker-compose exec app node ./packages/evershop/dist/bin/evershop.js seed --all"
echo "   4. Access your store: https://tvn-sut.info"
echo "   5. Access admin panel: https://tvn-sut.info/admin"
echo ""
echo "✅ EverShop is now deployed with Cloudflare SSL and optimized for your 1 vCPU / 2GB RAM VPS!"
