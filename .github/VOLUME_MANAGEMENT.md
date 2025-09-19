# Volume Management for n8n Deployment

## Current Configuration

The deployment uses **named volumes** with **no size limits** by default:

- `n8n-data`: Stores workflows, credentials, and n8n configuration
- `n8n-postgres-data`: Stores PostgreSQL database files

## Volume Behavior

### Default (Current)
- **Size**: Unlimited - uses all available host disk space
- **Growth**: Volumes grow as needed
- **Location**: `/var/lib/containers/storage/volumes/` (Podman) or `/var/lib/docker/volumes/` (Docker)

### Monitoring Volume Usage

To check current volume sizes:

```bash
# As n8n user
sudo -u n8n podman volume inspect n8n-data
sudo -u n8n podman volume inspect n8n-postgres-data

# Check actual disk usage
sudo du -sh /var/lib/containers/storage/volumes/n8n-data/_data
sudo du -sh /var/lib/containers/storage/volumes/n8n-postgres-data/_data
```

## Setting Volume Size Limits

### Option 1: Quota-based Limits (Recommended for Production)

Configure at the filesystem level:

```bash
# Example using XFS quotas
sudo xfs_quota -x -c "limit bsoft=10g bhard=12g n8n" /var/lib/containers
```

### Option 2: Device Mapper Storage (Docker only)

In `/etc/docker/daemon.json`:

```json
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.basesize=50G"
  ]
}
```

### Option 3: Bind Mounts with Dedicated Partitions

Modify the workflow to use bind mounts:

```yaml
# Instead of named volumes, use:
-v /data/n8n:/home/node/.n8n
-v /data/postgres:/var/lib/postgresql/data
```

Then create partitions with specific sizes:

```bash
# Create 50GB partition for n8n data
sudo lvcreate -L 50G -n n8n-data vg0
sudo mkfs.xfs /dev/vg0/n8n-data
sudo mount /dev/vg0/n8n-data /data/n8n

# Create 10GB partition for PostgreSQL
sudo lvcreate -L 10G -n postgres-data vg0
sudo mkfs.xfs /dev/vg0/postgres-data
sudo mount /dev/vg0/postgres-data /data/postgres
```

## Storage Recommendations

### Development Environment
- **n8n-data**: 5-10 GB
- **postgres-data**: 2-5 GB
- **Total**: ~15 GB

### Production Environment
- **n8n-data**: 20-50 GB (depends on workflow complexity and file storage)
- **postgres-data**: 10-20 GB
- **Total**: ~70 GB
- **Reserve**: Keep 20% free space for operations

### Factors Affecting Storage

1. **Workflow Complexity**: More nodes = more storage
2. **Execution History**: Stored in PostgreSQL
3. **Binary Data**: Files processed by workflows
4. **Logs**: Execution logs and debug information
5. **Backups**: If automated backups are configured

## Cleanup and Maintenance

### Remove old execution data (PostgreSQL)

```sql
-- Connect to n8n database
DELETE FROM execution_entity
WHERE "startedAt" < NOW() - INTERVAL '30 days'
AND status IN ('success', 'failed');

-- Reclaim space
VACUUM FULL;
```

### Prune unused volumes

```bash
# Remove unused volumes
sudo -u n8n podman volume prune

# Remove specific volume (WARNING: Data loss!)
sudo -u n8n podman volume rm n8n-data
```

### Check disk usage in workflow

The deployment workflow now includes:
1. Pre-deployment disk space check
2. Volume creation with optional size limits
3. Post-deployment volume usage report

## Monitoring Best Practices

1. **Set up alerts** for disk usage > 80%
2. **Regular cleanup** of old executions (monthly)
3. **Monitor growth rate** to predict future needs
4. **Backup before cleanup** operations

## Emergency Recovery

If volumes fill up:

1. **Stop n8n**: `podman stop n8n`
2. **Clean executions**: Run cleanup SQL
3. **Expand volume** if using LVM
4. **Restart n8n**: `podman start n8n`

## Future Improvements

To enable size limits in the workflow, uncomment these lines in `.github/workflows/deploy.yml`:

```bash
# Volume size limits (optional - uncomment to enable)
POSTGRES_VOLUME_SIZE="10G"  # PostgreSQL data
N8N_VOLUME_SIZE="50G"        # n8n workflows and data
```

Note: Size limits require specific storage drivers and may not work with all Podman/Docker configurations.