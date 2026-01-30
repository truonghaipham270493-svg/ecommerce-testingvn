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
#docker build -f Dockerfile.dev  --platform linux/amd64 -t $IMAGE_NAME:$TAG .
docker build -f Dockerfile.dev  -t $IMAGE_NAME:1 .

# Tag for registry
echo "🏷️  Tagging image for registry..."
docker tag ecommerce-testingvn:1 haiphamt1/testingvn:1

echo "✅ Image push"
#docker push haiphamt1/testingvn:latest