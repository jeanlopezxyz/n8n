# n8n Deployment Configuration

## GitHub Secrets Required

Configure these secrets in your GitHub repository settings:

### Repository Secrets
```yaml
# These are already available by default:
GITHUB_TOKEN: Automatically provided by GitHub Actions

# Optional secrets you may want to configure:
N8N_ENCRYPTION_KEY: <your-encryption-key>
N8N_USER_MANAGEMENT_JWT_SECRET: <your-jwt-secret>
WEBHOOK_URL: <your-webhook-url>
```

### Environment Variables
These are configured automatically by the deployment workflow:
- `DB_TYPE`: postgresdb
- `DB_POSTGRESDB_HOST`: n8n-postgres
- `DB_POSTGRESDB_DATABASE`: n8n
- `DB_POSTGRESDB_USER`: n8n
- `DB_POSTGRESDB_PASSWORD`: Auto-generated if not provided
- `N8N_PORT`: 5678
- `N8N_HOST`: Your server hostname

## Self-Hosted Runner Configuration

### Runner Requirements
- Label: `self-hosted`
- User: `n8n`
- Container Runtime: `podman`
- Network Access: GitHub, ghcr.io
- Ports: 5678 (n8n), 5432 (PostgreSQL internal)

### Runner Setup
```bash
# The runner must be configured to run as user 'n8n'
sudo useradd -m -s /bin/bash n8n
sudo usermod -aG docker n8n  # If using docker
sudo loginctl enable-linger n8n  # For podman rootless

# Install runner as user n8n
sudo -u n8n bash
cd /home/n8n
# Follow GitHub's self-hosted runner installation guide
```

## Workflow Usage

### Manual Deployment
```bash
# Deploy with new build
gh workflow run n8n-cicd.yml \
  --field environment=production \
  --field skip_build=false

# Deploy existing image
gh workflow run n8n-cicd.yml \
  --field environment=production \
  --field skip_build=true \
  --field image_tag=latest
```

### Automatic Deployment
The workflow triggers automatically on:
- Push to main/master branches
- Changes to docker/, packages/, or deployment files

### Pull Request Testing
- Automatically builds and tests on PR creation
- Does not deploy to production
- Runs security scans

## Environments

### Production
- URL: http://your-server:5678
- Database: PostgreSQL with persistent storage
- Auto-restart: Enabled
- Health checks: Every 30 seconds

### Staging
- URL: http://staging-server:5678
- Database: PostgreSQL (separate instance)
- Used for PR testing

### Development
- URL: http://dev-server:5678
- Database: PostgreSQL (can be SQLite)
- Debug mode enabled

## Monitoring

### Health Endpoints
- `/healthz` - Basic health check
- `/api/v1/health` - API health status

### Logs
```bash
# View n8n logs
sudo -u n8n podman logs n8n

# View PostgreSQL logs
sudo -u n8n podman logs n8n-postgres

# View runner logs
journalctl -u actions.runner.* -f
```

## Troubleshooting

### Common Issues

1. **Runner not picking up job**
   - Verify runner is online: `sudo -u n8n ~/actions-runner/run.sh`
   - Check runner labels match workflow requirements

2. **Container permission denied**
   - Ensure podman is configured for rootless mode
   - Check user n8n has proper permissions

3. **Database connection failed**
   - Verify PostgreSQL container is running
   - Check network connectivity between containers
   - Review PostgreSQL logs

4. **Port already in use**
   - Stop existing containers: `sudo -u n8n podman stop n8n n8n-postgres`
   - Change port mapping if needed

## Security Notes

- Never commit secrets to the repository
- Use GitHub Secrets for sensitive data
- Regularly rotate database passwords
- Keep runner and podman updated
- Use HTTPS for production deployments