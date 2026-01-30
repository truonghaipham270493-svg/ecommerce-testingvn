#!/bin/bash

# Cleanup script for EverShop Docker setup
echo "Cleaning up EverShop Docker setup..."

# Stop and remove containers
echo "Stopping and removing containers..."
docker compose down --volumes --remove-orphans 2>/dev/null || docker-compose down --volumes --remove-orphans 2>/dev/null

# Remove Docker volumes
echo "Removing Docker volumes..."
docker volume rm -f ecommerce-testingvn_postgres-data 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

# Remove Docker images
echo "Removing Docker images..."
docker rmi -f ecommerce-testingvn-app 2>/dev/null || true

# Clean up logs
echo "Cleaning up logs..."
rm -rf logs/nginx/* 2>/dev/null || true

echo "Cleanup completed!"
echo ""
echo "To start fresh, run:"
echo "  docker compose up --build"