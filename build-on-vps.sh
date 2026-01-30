#!/bin/bash

# Build EverShop on VPS with memory optimization
# Usage: Run this on your VPS in the project directory

set -e

echo "🔨 Building EverShop on VPS with memory optimization..."

# Check memory
echo "💾 Checking system memory..."
free -h

# Increase swap space for build
echo "🔄 Creating swap file for build..."
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

echo "📦 Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y python3 make g++

echo "🐳 Building Docker image with memory limits..."
# Build with memory limits and without parallel builds
docker build \
  --memory 1.5g \
  --memory-swap 2g \
  --no-cache \
  -f Dockerfile.prod \
  -t evershop:latest .

echo "✅ Build completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update .env file to use local image:"
echo "   DOCKER_IMAGE=evershop:latest"
echo ""
echo "2. Deploy:"
echo "   docker-compose up -d"
echo ""
echo "3. Remove swap file (optional):"
echo "   sudo swapoff /swapfile"
echo "   sudo rm /swapfile"