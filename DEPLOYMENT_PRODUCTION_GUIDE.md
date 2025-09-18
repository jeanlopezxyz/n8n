# 🚀 Guía de Deployment en Producción con PostgreSQL

Esta guía usa **ÚNICAMENTE** los recursos existentes del repositorio n8n para desplegar con PostgreSQL en producción.

## 📋 Pre-requisitos en el Servidor

- Docker o Podman instalado
- Puerto 5678 abierto (n8n)
- Puerto 5432 abierto (PostgreSQL, opcional)
- 2GB RAM mínimo
- 10GB espacio en disco

## 🔧 Configuración de GitHub Actions con Self-Hosted Runner

### 1. Instalar GitHub Runner en tu servidor

**Opción más segura - NO requiere exponer SSH**

En tu servidor, instala el GitHub Actions Runner:
- Ve a `Settings > Actions > Runners > New self-hosted runner` en tu repo
- Sigue las instrucciones para Linux
- Usa labels: `self-hosted, linux, production`

### 2. Ejecutar el Workflow

El workflow usa los archivos existentes del repositorio:
- `docker-compose-postgres.yml` - Configuración completa con PostgreSQL
- `deploy-n8n-postgres.sh` - Script de deployment existente (compatible con podman)
- No requiere SSH - usa el runner local

Para ejecutar:

1. Ve a `Actions` > `Deploy n8n Production with PostgreSQL (Self-Hosted Runner)`
2. Click en `Run workflow`
3. Selecciona el environment (production/staging)
4. Click `Run workflow`

**Ventajas de usar Self-Hosted Runner:**
- ✅ NO expone puerto SSH (puerto 22 cerrado)
- ✅ Ejecuta directamente en el servidor
- ✅ Más seguro y rápido
- ✅ Compatible con podman y docker

## 🖥️ Deployment Manual (Sin GitHub Actions)

Si prefieres hacerlo manualmente desde el repositorio n8n:

```bash
# 1. Clonar el repositorio en el servidor
ssh usuario@servidor
git clone https://github.com/tu-usuario/n8n.git
cd n8n

# 2. Ejecutar el script de deployment existente
chmod +x deploy-n8n-postgres.sh
./deploy-n8n-postgres.sh

# El script automáticamente:
# - Configura PostgreSQL
# - Genera passwords seguros
# - Inicia todos los servicios
# - Configura backups automáticos
```

## 📦 Estructura del Deployment

El deployment usa la configuración existente del repositorio:

### Servicios Docker (docker-compose-postgres.yml):
- **n8n**: Aplicación principal (imagen: ghcr.io/jeanlopezxyz/n8n:latest)
- **postgres**: Base de datos PostgreSQL 15
- **postgres-backup**: Backups automáticos diarios

### Volúmenes Persistentes:
- `postgres_data`: Datos de PostgreSQL
- `postgres_backups`: Backups automáticos
- `n8n_files`: Archivos de n8n
- `n8n_custom`: Configuraciones custom

### Características:
- ✅ Base de datos PostgreSQL real (no SQLite)
- ✅ Backups automáticos diarios
- ✅ Health checks configurados
- ✅ Reinicio automático en caso de fallo
- ✅ Persistencia total de datos
- ✅ Usa scripts y configs del repo

## 🔐 Seguridad

El script `deploy-n8n-postgres.sh` del repositorio genera automáticamente:
- Password seguro para PostgreSQL
- Password de admin para n8n
- N8N_ENCRYPTION_KEY para seguridad

Las credenciales se guardan en `.env` en el servidor.

**Seguridad mejorada con Self-Hosted Runner:**
- No requiere exponer SSH (puerto 22)
- Runner se ejecuta con usuario no-root
- Solo acepta jobs de tu repositorio
- Logs auditables en el servidor

## 🌐 Acceso

Después del deployment:
- **URL**: http://[servidor]:5678
- **Usuario**: admin
- **Password**: Ver archivo `.env` en el servidor

```bash
# Ver credenciales
cat /opt/n8n/.env
```

## 🔄 Actualización

Para actualizar n8n usando los archivos del repo:

```bash
cd /opt/n8n

# Pull última versión
docker-compose -f docker-compose-postgres.yml pull

# Aplicar cambios
docker-compose -f docker-compose-postgres.yml up -d
```

## 🛠️ Comandos Útiles

```bash
# Ver logs (podman o docker)
podman-compose -f docker-compose-postgres.yml logs -f
# o
docker-compose -f docker-compose-postgres.yml logs -f

# Backup manual de base de datos
podman exec n8n-postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Restaurar backup
podman exec -i n8n-postgres psql -U n8n n8n < backup.sql

# Ver estado de servicios
podman-compose -f docker-compose-postgres.yml ps

# Reiniciar servicios
podman-compose -f docker-compose-postgres.yml restart

# Ver contenedores
podman ps | grep -E "n8n|postgres"
```

## 📊 Monitoreo

El deployment incluye health checks automáticos configurados en docker-compose-postgres.yml:
- PostgreSQL: cada 10 segundos
- n8n: cada 30 segundos

## ⚠️ Importante

- **NO modifiques** el `N8N_ENCRYPTION_KEY` después de la primera instalación
- Los backups se mantienen por 7 días automáticamente
- El puerto 5432 de PostgreSQL está expuesto (puedes comentarlo si no lo necesitas)
- Todos los archivos de configuración están en el repositorio

## 🆘 Troubleshooting

Si algo falla:

1. **Revisar logs**:
   ```bash
   docker-compose -f docker-compose-postgres.yml logs n8n
   docker-compose -f docker-compose-postgres.yml logs postgres
   ```

2. **Verificar recursos**:
   ```bash
   df -h          # Espacio en disco
   free -m        # Memoria RAM
   docker ps -a   # Contenedores
   ```

3. **Verificar conectividad a base de datos**:
   ```bash
   docker exec n8n-postgres pg_isready -U n8n
   ```

4. **Reiniciar servicios**:
   ```bash
   docker-compose -f docker-compose-postgres.yml down
   docker-compose -f docker-compose-postgres.yml up -d
   ```

## 📁 Archivos del Repositorio Utilizados

- `.github/workflows/deploy-production-postgres.yml` - Workflow con self-hosted runner
- `docker-compose-postgres.yml` - Configuración compatible con docker/podman
- `deploy-n8n-postgres.sh` - Script que detecta automáticamente docker o podman
- No se crean archivos innecesarios - usa 100% lo existente

---

Este deployment usa **100% recursos existentes del repositorio n8n**, garantizando persistencia completa con PostgreSQL.