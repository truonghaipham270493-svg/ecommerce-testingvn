#!/bin/bash

# Debug script for stuck EverShop app container
# Usage: ./debug-app.sh

set -e

echo "🔍 Debugging stuck EverShop app container..."

echo "1. Checking container status..."
docker compose ps

echo ""
echo "2. Checking app logs..."
docker compose logs app --tail=50

echo ""
echo "3. Checking database connection..."
docker compose exec database pg_isready -U ${DB_USER:-evershop} || echo "Database not ready"

echo ""
echo "4. Testing database connection from app container..."
docker compose exec app sh -c "
echo 'Testing database connection...'
node -e \"
const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.DB_HOST || 'database',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'evershop',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'evershop',
  connectionTimeoutMillis: 5000
});

pool.query('SELECT 1', (err, res) => {
  if (err) {
    console.error('❌ Database connection error:', err.message);
    console.error('Environment variables:');
    console.error('DB_HOST:', process.env.DB_HOST);
    console.error('DB_USER:', process.env.DB_USER);
    console.error('DB_NAME:', process.env.DB_NAME);
    process.exit(1);
  } else {
    console.log('✅ Database connection successful');
    process.exit(0);
  }
});
\"
"

echo ""
echo "5. Checking app container processes..."
docker compose exec app ps aux

echo ""
echo "6. Checking if EverShop is listening..."
docker compose exec app sh -c "netstat -tulpn | grep :3000 || echo 'Not listening on port 3000'"

echo ""
echo "7. Common issues and fixes:"
echo "   a) Database password mismatch - check .env file"
echo "   b) Missing Docker image - build with: docker build -f Dockerfile.prod -t evershop:latest ."
echo "   c) Port conflict - check if port 3000 is already in use"
echo "   d) Memory issues - check docker stats"
echo ""
echo "8. Quick fixes to try:"
echo "   - Restart app: docker-compose restart app"
echo "   - Rebuild image: docker build -f Dockerfile.prod -t evershop:latest ."
echo "   - Check .env: cat .env"
echo "   - Full restart: docker-compose down && docker-compose up -d"