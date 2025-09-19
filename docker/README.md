# Docker Configuration Files

This directory contains Docker-related configuration files for the n8n deployment.

## Files Overview

### `Caddyfile`
**Purpose**: Caddy reverse proxy configuration for HTTPS/TLS termination
- Automatic SSL certificate management with Let's Encrypt
- HTTP to HTTPS redirection
- Security headers configuration
- Reverse proxy setup for n8n
- Health check endpoints

**Usage**: Used by both the GitHub Actions workflow and docker-compose setup

### `docker-compose.https.yml`
**Purpose**: Complete stack for local development and testing
- PostgreSQL 15 (database)
- Redis 7 (queue and cache)
- n8n (workflow automation)
- Caddy 2 (HTTPS reverse proxy)

**Usage**: Local development and testing
```bash
# Set environment variables
export N8N_DOMAIN=localhost
export POSTGRES_PASSWORD=secure_password
export N8N_ENCRYPTION_KEY=your-32-character-key

# Start the stack
docker-compose -f docker/docker-compose.https.yml up -d

# Check status
docker-compose -f docker/docker-compose.https.yml ps

# View logs
docker-compose -f docker/docker-compose.https.yml logs -f

# Stop the stack
docker-compose -f docker/docker-compose.https.yml down
```

## Environment Variables

### Required
- `N8N_DOMAIN`: Your domain name (e.g., "n8n.yourdomain.com" or "localhost")
- `POSTGRES_PASSWORD`: Strong password for PostgreSQL
- `N8N_ENCRYPTION_KEY`: 32+ character encryption key for n8n

### Optional
- `CADDY_EMAIL`: Email for Let's Encrypt notifications

## Quick Start (Local Development)

1. **Set environment variables**:
```bash
export N8N_DOMAIN=localhost
export POSTGRES_PASSWORD=my_secure_password
export N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
```

2. **Start the stack**:
```bash
docker-compose -f docker/docker-compose.https.yml up -d
```

3. **Access n8n**:
- HTTP: http://localhost (redirects to HTTPS)
- HTTPS: https://localhost (with self-signed certificate)

4. **Check health**:
```bash
# All services should show as "healthy"
docker-compose -f docker/docker-compose.https.yml ps
```

## Production Deployment

For production, use the GitHub Actions workflow which:
- Uses Podman instead of Docker
- Implements proper resource limits
- Manages secrets securely
- Provides automated deployment and health checks

## Security Notes

- Never commit secrets to the repository
- Use strong, unique passwords
- For production, configure a real domain with proper DNS
- Monitor certificate expiration (auto-renewal should handle this)
- Regular backups of volumes are recommended

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 80, 443, and 2019 are available
2. **SSL certificate issues**: For localhost, expect self-signed certificate warnings
3. **Container startup order**: Services have health checks and dependencies configured
4. **Domain resolution**: For real domains, ensure DNS is properly configured

### Useful Commands

```bash
# Check container logs
docker-compose -f docker/docker-compose.https.yml logs <service-name>

# Execute commands in containers
docker-compose -f docker/docker-compose.https.yml exec n8n /bin/sh
docker-compose -f docker/docker-compose.https.yml exec postgres psql -U n8n -d n8n

# Check SSL certificate (for real domains)
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Test endpoints
curl -k https://localhost/healthz
curl http://localhost:8080/health
```

## Volume Persistence

Data is persisted in named Docker volumes:
- `postgres_data`: PostgreSQL database
- `redis_data`: Redis data
- `n8n_data`: n8n workflows and settings
- `caddy_data`: SSL certificates and Caddy data
- `caddy_config`: Caddy configuration cache

To backup data:
```bash
docker run --rm -v docker_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-backup.tar.gz -C /data .
```

To restore data:
```bash
docker run --rm -v docker_n8n_data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n-backup.tar.gz -C /data
```