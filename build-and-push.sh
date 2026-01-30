#!/bin/bash

# Build and push EverShop Docker image locally
# Usage: ./build-and-push.sh [registry-url]

set -e

echo "🔨 Building EverShop Docker image locally..."

# Default registry (Docker Hub)
REGISTRY=${1:-"docker.io"}
IMAGE_NAME="ecommerce-testingvn"
TAG="latest"

# Build the image locally
echo "🏗️  Building Docker image..."
docker build -f Dockerfile.dev -t $IMAGE_NAME:$TAG .

# Tag for registry
echo "🏷️  Tagging image for registry..."
docker tag $IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:$TAG

echo "✅ Image built and tagged as:"
echo "   - Local: $IMAGE_NAME:$TAG"
echo "   - Registry: $REGISTRY/$IMAGE_NAME:$TAG"

echo ""
echo "📋 Next steps:"
echo "1. Login to registry:"
echo "   docker login $REGISTRY"
echo ""
echo "2. Push image to registry:"
echo "   docker push $REGISTRY/$IMAGE_NAME:$TAG"
echo ""
echo "3. On VPS, update docker-compose.prod.yml to use the registry image:"
echo "   Change 'build:' to 'image: $REGISTRY/$IMAGE_NAME:$TAG'"
echo ""
echo "4. Deploy on VPS:"
echo "   cd /opt/evershop"
echo "   docker-compose pull"
echo "   docker-compose up -d"