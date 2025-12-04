#!/bin/bash
set -e

# Get database connection details from environment variables
DB_NAME="${POSTGRES_DB:-mysite}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

# If DATABASE_URL is provided, extract values from it (overrides individual vars)
if [ -n "$DATABASE_URL" ]; then
    # Extract host and port from postgres://user:pass@host:port/db format
    DB_HOST=$(echo $DATABASE_URL | sed -E 's/.*@([^:]+):.*/\1/')
    DB_PORT=$(echo $DATABASE_URL | sed -E 's/.*:([0-9]+)\/.*/\1/')
    DB_USER=$(echo $DATABASE_URL | sed -E 's/.*:\/\/([^:]+):.*/\1/')
    DB_NAME=$(echo $DATABASE_URL | sed -E 's/.*\/([^?]+).*/\1/')
fi

echo "Database configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"

echo "Waiting for postgres at $DB_HOST:$DB_PORT..."

# Wait for database with timeout (30 seconds max)
timeout=30
counter=0
while ! nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "Warning: Could not connect to database after ${timeout}s, proceeding anyway..."
        break
    fi
    sleep 1
done

if [ $counter -le $timeout ]; then
    echo "PostgreSQL is ready!"
fi

echo "Running database migrations..."
python manage.py migrate

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting application..."
exec gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 2 --access-logfile -
