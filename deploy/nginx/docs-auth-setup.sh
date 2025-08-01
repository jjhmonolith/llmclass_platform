#!/bin/bash

# Script to setup Basic Auth for API documentation
# Usage: ./docs-auth-setup.sh <username> <password>

set -e

USERNAME="${1:-admin}"
PASSWORD="${2:-secret}"

echo "🔐 Setting up Basic Auth for API documentation..."
echo "Username: $USERNAME"

# Create .htpasswd file with bcrypt encryption
docker run --rm httpd:2.4-alpine htpasswd -nbB "$USERNAME" "$PASSWORD" > .htpasswd

echo "✅ Basic Auth credentials created in .htpasswd"
echo ""
echo "📝 To enable Basic Auth in production:"
echo "1. Copy .htpasswd to the nginx container:"
echo "   docker compose exec proxy cp /app/.htpasswd /etc/nginx/.htpasswd"
echo ""
echo "2. Uncomment these lines in nginx.conf:"
echo "   # auth_basic \"API Documentation\";"
echo "   # auth_basic_user_file /etc/nginx/.htpasswd;"
echo ""
echo "3. Restart nginx:"
echo "   docker compose restart proxy"
echo ""
echo "🔒 Documentation will then require login:"
echo "   Username: $USERNAME"
echo "   Password: [as provided]"