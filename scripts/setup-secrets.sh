#!/bin/bash

# Setup Secrets Script for n8n HTTPS Deployment
# This script helps you generate and configure the required secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_status $BLUE "=== $1 ==="
}

print_header "n8n HTTPS Secrets Setup"

print_status $YELLOW "This script will help you generate secure values for your GitHub repository secrets."
print_status $YELLOW "You'll need to manually add these to your GitHub repository: Settings → Secrets and variables → Actions"
echo ""

# Generate encryption key
print_header "1. n8n Encryption Key"
print_status $BLUE "Generating a secure encryption key for n8n..."

if command -v openssl &> /dev/null; then
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    print_status $GREEN "Generated encryption key:"
    echo "N8N_ENCRYPTION_KEY: $ENCRYPTION_KEY"
else
    print_status $YELLOW "OpenSSL not found. Generating fallback key..."
    ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
    print_status $GREEN "Generated encryption key:"
    echo "N8N_ENCRYPTION_KEY: $ENCRYPTION_KEY"
fi

echo ""

# Generate PostgreSQL password
print_header "2. PostgreSQL Password"
print_status $BLUE "Generating a secure password for PostgreSQL..."

if command -v openssl &> /dev/null; then
    POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
else
    POSTGRES_PASSWORD=$(head -c 18 /dev/urandom | base64 | tr -d "=+/" | cut -c1-24)
fi

print_status $GREEN "Generated PostgreSQL password:"
echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"

echo ""

# Domain configuration
print_header "3. Domain Configuration"
print_status $BLUE "Enter your domain name for n8n (e.g., n8n.yourdomain.com):"
read -p "Domain: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    print_status $YELLOW "No domain entered. Using 'localhost' for development."
    DOMAIN="localhost"
fi

print_status $GREEN "Domain configuration:"
echo "N8N_DOMAIN: $DOMAIN"

echo ""

# Email for Let's Encrypt (optional)
if [[ "$DOMAIN" != "localhost" && "$DOMAIN" != "127.0.0.1" ]]; then
    print_header "4. Let's Encrypt Email (Optional)"
    print_status $BLUE "Enter your email for Let's Encrypt certificate notifications (optional):"
    read -p "Email (or press Enter to skip): " LETSENCRYPT_EMAIL

    if [[ -n "$LETSENCRYPT_EMAIL" ]]; then
        print_status $GREEN "Let's Encrypt email:"
        echo "CADDY_EMAIL: $LETSENCRYPT_EMAIL"
    else
        print_status $YELLOW "No email provided. Caddy will use anonymous certificates."
    fi
fi

echo ""

# Summary
print_header "GitHub Repository Secrets Summary"
print_status $GREEN "Copy these values to your GitHub repository secrets:"
echo ""
echo "Required secrets:"
echo "  N8N_ENCRYPTION_KEY: $ENCRYPTION_KEY"
echo "  POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "  N8N_DOMAIN: $DOMAIN"

if [[ -n "$LETSENCRYPT_EMAIL" ]]; then
echo ""
echo "Optional secrets:"
echo "  CADDY_EMAIL: $LETSENCRYPT_EMAIL"
fi

echo ""

print_header "Next Steps"
print_status $BLUE "1. Add the above secrets to your GitHub repository:"
echo "   - Go to: Settings → Secrets and variables → Actions"
echo "   - Click 'New repository secret'"
echo "   - Add each secret with its name and value"

echo ""
print_status $BLUE "2. Configure DNS (if using a real domain):"
echo "   - Create an A record pointing $DOMAIN to your server's public IP"
echo "   - Wait for DNS propagation (can take up to 48 hours)"

echo ""
print_status $BLUE "3. Configure firewall:"
echo "   - Allow port 80 (HTTP) and 443 (HTTPS)"
echo "   - Example: sudo ufw allow 80 && sudo ufw allow 443"

echo ""
print_status $BLUE "4. Deploy:"
echo "   - Push your changes to trigger the GitHub Actions workflow"
echo "   - Monitor the deployment in the Actions tab"

echo ""
print_status $BLUE "5. Test the setup:"
echo "   - Run: ./scripts/test-https-setup.sh"
echo "   - Access your n8n instance at: https://$DOMAIN"

echo ""
print_header "Security Notes"
print_status $YELLOW "- Store these values securely (consider using a password manager)"
print_status $YELLOW "- Never commit secrets to your repository"
print_status $YELLOW "- Rotate these values periodically for better security"
print_status $YELLOW "- Monitor your certificates for expiration (auto-renewal should handle this)"

echo ""
print_status $GREEN "Setup complete! Review the HTTPS_SETUP_GUIDE.md for detailed instructions."