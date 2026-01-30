#!/bin/bash

# EverShop VPS Deployment Script using pre-built image
# Usage: Run this script in the project folder after cloning from Git

set -e

echo "🚀 Starting EverShop deployment to VPS (using pre-built image)..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Get current directory
PROJECT_DIR=$(pwd)
echo "📁 Project directory: $PROJECT_DIR"

# Update system (optional)
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y || echo "System update skipped"

# Install Docker and Docker Compose if not installed
echo "🐳 Checking for Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
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
# Change this to your registry/image if using custom registry
# DOCKER_IMAGE=docker.io/evershop:latest
EOF

echo "✅ Environment file created at $PROJECT_DIR/.env"

# Use docker-compose.pull.yml
echo "🐳 Setting up Docker Compose with pre-built image..."
if [ -f docker-compose.pull.yml ]; then
    cp docker-compose.pull.yml docker-compose.yml
    echo "✅ Created docker-compose.yml from docker-compose.pull.yml"
    
    # Ask for custom image if needed
    read -p "Enter Docker image name [docker.io/evershop:latest]: " DOCKER_IMAGE
    DOCKER_IMAGE=${DOCKER_IMAGE:-docker.io/evershop:latest}
    
    # Update docker-compose.yml with custom image
    sed -i "s|image: docker.io/evershop:latest|image: $DOCKER_IMAGE|g" docker-compose.yml
    echo "✅ Updated docker-compose.yml with image: $DOCKER_IMAGE"
else
    echo "❌ docker-compose.pull.yml not found!"
    exit 1
fi

# Pull the Docker image
echo "📥 Pulling Docker image..."
docker-compose pull app || echo "⚠️  Could not pull image. Make sure it exists in the registry."

# Start services
echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Deployment Summary:"
echo "   - Using pre-built Docker image: $DOCKER_IMAGE"
echo "   - No build required on VPS"
echo "   - Optimized for 1 vCPU / 2GB RAM"
echo ""
echo "🔧 Management Commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Restart: docker-compose restart"
echo "   - Stop: docker-compose down"
echo "   - Update image: docker-compose pull app && docker-compose up -d"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Set up SSL certificates (if not already done):"
echo "      ./setup-ssl.sh"
echo "   2. Run seed data:"
echo "      docker-compose exec app node ./packages/evershop/dist/bin/evershop.js seed --all"
echo "   3. Access your store: http://tvn-sut.info"
echo ""
echo "✅ EverShop deployed using pre-built image!"