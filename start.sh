#!/bin/bash

# Startup script for EverShop with nginx and seed data
echo "Starting EverShop with nginx reverse proxy..."

# Make sure the cleanup script is executable
chmod +x cleanup.sh 2>/dev/null || true

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if we should clean up first
if [[ "$1" == "--clean" ]] || [[ "$1" == "-c" ]]; then
    echo "Cleaning up before starting..."
    ./cleanup.sh
fi

# Build and start the services
echo "Building and starting services..."
if command -v docker-compose &> /dev/null; then
    docker-compose up --build
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    docker compose up --build
else
    echo "Error: Neither docker-compose nor docker compose is available"
    exit 1
fi