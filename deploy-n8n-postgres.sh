#!/bin/bash

# Script para desplegar n8n con PostgreSQL
# Persistencia garantizada con base de datos real

set -e

echo "🚀 Desplegando n8n con PostgreSQL para persistencia real"
echo "=================================================="

# Detectar runtime
if command -v podman-compose &> /dev/null; then
    COMPOSE="podman-compose"
    RUNTIME="podman"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
    RUNTIME="docker"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE="docker compose"
    RUNTIME="docker"
else
    echo "❌ No se encontró docker-compose o podman-compose"
    echo "Instalando podman-compose..."
    pip3 install --user podman-compose
    COMPOSE="podman-compose"
    RUNTIME="podman"
fi

echo "📦 Usando: $COMPOSE ($RUNTIME)"

# Configurar variables de entorno
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-n8n_secure_$(openssl rand -hex 12)}"
export N8N_BASIC_AUTH_PASSWORD="${N8N_BASIC_AUTH_PASSWORD:-n8n_admin_$(openssl rand -hex 8)}"

echo ""
echo "📝 Configuración:"
echo "  PostgreSQL Password: $POSTGRES_PASSWORD"
echo "  n8n Admin Password: $N8N_BASIC_AUTH_PASSWORD"
echo ""

# Guardar credenciales
cat > .env <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD
N8N_HOST=server1.labjp.xyz
N8N_PROTOCOL=http
TZ=America/Mexico_City
EOF

echo "💾 Credenciales guardadas en .env"

# Detener servicios existentes
echo "🛑 Deteniendo servicios anteriores..."
$COMPOSE -f docker-compose-postgres.yml down 2>/dev/null || true
$RUNTIME stop n8n 2>/dev/null || true
$RUNTIME rm n8n 2>/dev/null || true

# Iniciar servicios
echo "🔧 Iniciando servicios..."
$COMPOSE -f docker-compose-postgres.yml up -d

# Esperar a que PostgreSQL esté listo
echo "⏳ Esperando a que PostgreSQL esté listo..."
sleep 10

# Verificar servicios
echo "✅ Verificando servicios..."
$COMPOSE -f docker-compose-postgres.yml ps

# Mostrar logs
echo ""
echo "📋 Logs de n8n:"
$COMPOSE -f docker-compose-postgres.yml logs n8n --tail=20

echo ""
echo "=================================================="
echo "✅ n8n desplegado con PostgreSQL!"
echo ""
echo "🌐 Acceder a n8n:"
echo "   URL: http://server1.labjp.xyz:5678"
echo "   Usuario: admin"
echo "   Password: $N8N_BASIC_AUTH_PASSWORD"
echo ""
echo "🗄️ Base de datos PostgreSQL:"
echo "   Host: localhost"
echo "   Puerto: 5432"
echo "   Database: n8n"
echo "   Usuario: n8n"
echo "   Password: $POSTGRES_PASSWORD"
echo ""
echo "📊 Comandos útiles:"
echo "   Ver logs: $COMPOSE -f docker-compose-postgres.yml logs -f"
echo "   Detener: $COMPOSE -f docker-compose-postgres.yml down"
echo "   Backup DB: $RUNTIME exec n8n-postgres pg_dump -U n8n n8n > backup.sql"
echo "   Ver volúmenes: $RUNTIME volume ls"
echo ""
echo "💾 Los datos están persistidos en volúmenes Docker/Podman:"
echo "   - postgres_data (base de datos)"
echo "   - postgres_backups (backups automáticos)"
echo "   - n8n_files (archivos)"
echo "=================================================="