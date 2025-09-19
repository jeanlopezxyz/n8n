# Resource Limits Configuration for n8n Stack

## 📊 Current Configuration

### ⚠️ **IMPORTANT**: Currently NO resource limits are enforced!
All containers can use 100% of host resources, which can cause:
- One container monopolizing all RAM
- System crashes if memory runs out
- Performance degradation

## 🔴 Redis Configuration

### Current Settings:
```bash
--maxmemory 256mb            # Redis internal limit
--maxmemory-policy allkeys-lru  # Eviction policy
```

### Recommended Container Limits:
```bash
--memory="512m"      # Container memory limit
--memory-swap="512m" # No swap (same as memory)
--cpus="0.5"        # Half CPU core
```

### Why these limits?
- Redis needs 256MB for data + overhead for operations
- 512MB container limit gives breathing room
- 0.5 CPU is plenty for Redis (it's single-threaded)

## 🗄️ PostgreSQL Configuration

### Current Settings:
```bash
# NO LIMITS - Can use all available resources ⚠️
```

### Recommended Container Limits:
```bash
--memory="1g"        # 1GB RAM
--memory-swap="1g"   # No swap
--cpus="1.0"        # 1 CPU core
```

### Recommended PostgreSQL Tuning:
```bash
-e POSTGRES_SHARED_BUFFERS="256MB"      # 25% of RAM
-e POSTGRES_EFFECTIVE_CACHE_SIZE="768MB" # 75% of RAM
-e POSTGRES_MAX_CONNECTIONS="100"
-e POSTGRES_WORK_MEM="4MB"
```

## 📦 n8n Configuration

### Current Settings:
```bash
# NO LIMITS - Can use all available resources ⚠️
```

### Recommended Container Limits:
```bash
--memory="2g"        # 2GB RAM
--memory-swap="2g"   # No swap
--cpus="2.0"        # 2 CPU cores
```

### Why these limits?
- n8n needs RAM for workflow execution
- Complex workflows can be CPU intensive
- 2GB handles most workloads

## 💾 Storage Volumes

### Current Configuration:
```bash
n8n-postgres-data     # UNLIMITED ⚠️
n8n-data             # UNLIMITED ⚠️
n8n-redis-data       # UNLIMITED ⚠️
```

### Recommended Limits:

| Volume | Development | Production | Notes |
|--------|------------|------------|--------|
| **n8n-postgres-data** | 5GB | 20GB | Grows with execution history |
| **n8n-data** | 10GB | 50GB | Workflows, files, credentials |
| **n8n-redis-data** | 1GB | 2GB | Queue data, temporary |

## 🎯 Complete Resource Allocation

### Minimum Requirements (Development):
```
Total RAM:  4GB
- n8n:      2GB
- PostgreSQL: 1GB
- Redis:    512MB
- System:   512MB

Total CPU:  2 cores
- n8n:      2.0
- PostgreSQL: 1.0
- Redis:    0.5
(Oversubscription OK for dev)

Total Storage: 20GB
- OS:       5GB
- Volumes:  15GB
```

### Recommended for Production:
```
Total RAM:  8GB
- n8n:      3GB
- PostgreSQL: 2GB
- Redis:    1GB
- System:   2GB

Total CPU:  4 cores
- n8n:      2.0
- PostgreSQL: 1.0
- Redis:    0.5
- System:   0.5

Total Storage: 100GB
- OS:       10GB
- Volumes:  70GB
- Reserve:  20GB
```

## 🚀 How to Apply These Limits

### Option 1: Update deploy.yml (Podman/Docker)
```bash
# For PostgreSQL
podman run -d \
  --memory="1g" \
  --memory-swap="1g" \
  --cpus="1.0" \
  ...

# For Redis
podman run -d \
  --memory="512m" \
  --memory-swap="512m" \
  --cpus="0.5" \
  ...

# For n8n
podman run -d \
  --memory="2g" \
  --memory-swap="2g" \
  --cpus="2.0" \
  ...
```

### Option 2: Use docker-compose.yml
```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  redis:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  n8n:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

### Option 3: Systemd Resource Control
```ini
# /etc/systemd/system/podman-n8n.service
[Service]
MemoryLimit=2G
CPUQuota=200%
```

## 📈 Monitoring Resource Usage

### Check current usage:
```bash
# Container stats
podman stats --no-stream

# Volume sizes
for vol in n8n-data n8n-postgres-data n8n-redis-data; do
  echo "$vol: $(podman volume inspect $vol --format '{{.Mountpoint}}' | xargs du -sh 2>/dev/null)"
done

# System resources
free -h
df -h
top
```

### Set up alerts:
```bash
# Alert if container uses > 90% of limit
podman events --filter event=oom
```

## ⚠️ Warning Signs You Need More Resources

### Redis
- Eviction rate > 0 (check INFO stats)
- OOM errors
- Slow queue processing

### PostgreSQL
- Slow queries (> 1 second)
- Connection refused
- Cache hit ratio < 90%

### n8n
- UI becomes unresponsive
- Workflows fail with memory errors
- Execution timeout

## 🔧 Performance Tuning Tips

1. **Start conservative** - You can always increase limits
2. **Monitor for a week** - See actual usage patterns
3. **Scale vertically first** - Increase limits before adding nodes
4. **Use swap carefully** - Better to increase memory than rely on swap
5. **Reserve 20% headroom** - Don't run at 100% capacity

## 📊 Resource Planning Calculator

```javascript
// Simple formula for sizing:
function calculateResources(workflows_per_hour, avg_nodes_per_workflow) {
  const base_ram_gb = 1;
  const ram_per_100_workflows = 0.5;
  const ram_per_10_nodes = 0.1;

  const n8n_ram = base_ram_gb +
    (workflows_per_hour / 100) * ram_per_100_workflows +
    (avg_nodes_per_workflow / 10) * ram_per_10_nodes;

  return {
    n8n_ram_gb: Math.ceil(n8n_ram),
    postgres_ram_gb: Math.ceil(n8n_ram * 0.5),
    redis_ram_mb: 256 + Math.floor(workflows_per_hour * 2),
    total_ram_gb: Math.ceil(n8n_ram * 2)
  };
}

// Example: 100 workflows/hour, 20 nodes average
// Result: 4GB total RAM recommended
```

## 🚨 Emergency: Out of Resources

### Quick fixes:
```bash
# 1. Clean up old executions
podman exec n8n-postgres psql -U n8n -c "DELETE FROM execution_entity WHERE finished < NOW() - INTERVAL '7 days';"

# 2. Clear Redis
podman exec n8n-redis redis-cli FLUSHDB

# 3. Restart containers with higher limits
podman stop n8n n8n-postgres n8n-redis
# Edit limits in deploy.yml
# Redeploy

# 4. Prune unused volumes/images
podman system prune -a
```

## 📝 Best Practices

1. **Always set memory limits** - Prevent OOM killer
2. **Never disable swap at OS level** - Safety net
3. **Monitor before increasing** - Data-driven decisions
4. **Document changes** - Track what worked
5. **Test limits in staging** - Not in production

Remember: It's better to have limits and increase them than to have no limits and crash!