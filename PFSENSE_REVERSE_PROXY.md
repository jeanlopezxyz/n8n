# Configuración de pfSense como Reverse Proxy para n8n

## Ventajas de usar pfSense

- **Ya tienes la infraestructura**: No necesitas contenedores adicionales
- **Certificados centralizados**: Gestión única de SSL/TLS
- **Firewall integrado**: Mayor seguridad
- **Un solo punto de entrada**: Todas tus aplicaciones tras pfSense

## Arquitectura

```
Internet → pfSense (Firewall + Reverse Proxy) → n8n:5678
              ↓
         Certificado SSL
```

## Configuración paso a paso

### 1. Instalar HAProxy en pfSense

1. Ve a **System → Package Manager → Available Packages**
2. Busca **haproxy** o **haproxy-devel**
3. Click en **Install**

### 2. Crear certificado SSL

#### Opción A: Let's Encrypt (Recomendado)
1. Instala el paquete **ACME**
2. Ve a **Services → ACME → Certificates**
3. Crea nuevo certificado:
   - Domain: `n8n.tudominio.com`
   - Method: DNS o HTTP validation

#### Opción B: Certificado manual
1. Ve a **System → Cert Manager → Certificates**
2. **Add/Sign** → Crear nuevo certificado
3. Configura tu dominio

### 3. Configurar HAProxy Backend

Ve a **Services → HAProxy → Backend**

```
Name: n8n_backend
Server list:
  - Name: n8n_server
  - Address: [IP_DEL_SERVIDOR_N8N]
  - Port: 5678
  - SSL: No (comunicación interna)

Health check:
  - Health check method: HTTP
  - HTTP check path: /healthz
```

### 4. Configurar HAProxy Frontend

Ve a **Services → HAProxy → Frontend**

```
Name: HTTPS_Frontend
External address:
  - Listen address: WAN address
  - Port: 443
  - SSL Offloading: ✓

SSL Certificate: [Selecciona tu certificado]

ACL:
  - Name: n8n_acl
  - Expression: Host matches
  - Value: n8n.tudominio.com

Actions:
  - Action: Use Backend
  - Condition ACL: n8n_acl
  - Backend: n8n_backend
```

### 5. Configurar redirección HTTP → HTTPS

Crea otro Frontend:

```
Name: HTTP_Frontend
External address:
  - Listen address: WAN address
  - Port: 80

Actions:
  - Action: http-request redirect
  - Rule: scheme https
```

### 6. Headers de seguridad (Opcional)

En el Frontend HTTPS, agrega en **Advanced settings**:

```
http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
http-response set-header X-Content-Type-Options "nosniff"
http-response set-header X-Frame-Options "SAMEORIGIN"
http-response set-header X-XSS-Protection "1; mode=block"
```

### 7. Configurar Firewall

Ve a **Firewall → Rules → WAN**

Agrega reglas para:
- Puerto 443 (HTTPS)
- Puerto 80 (HTTP)
- Destino: This Firewall

### 8. Configurar DNS

En tu proveedor de DNS:
```
n8n.tudominio.com → IP_PUBLICA_DE_PFSENSE
```

## Configuración en n8n

Actualiza los secrets en GitHub:

```bash
N8N_HOST=n8n.tudominio.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.tudominio.com
N8N_SECURE_COOKIE=true
```

## Verificación

1. **Test desde pfSense**:
   ```
   Diagnostics → Test Port → Host: IP_SERVIDOR_N8N Port: 5678
   ```

2. **Test de SSL**:
   ```bash
   openssl s_client -connect n8n.tudominio.com:443
   ```

3. **Test de acceso**:
   ```bash
   curl -I https://n8n.tudominio.com
   ```

## Solución de problemas

### Error: "Secure cookie"
- Verifica que `N8N_PROTOCOL=https` esté configurado
- Confirma que accedes via HTTPS, no HTTP

### Error: "502 Bad Gateway"
- Verifica que n8n está corriendo: `podman ps`
- Confirma la IP del servidor en HAProxy backend
- Revisa los logs de HAProxy en pfSense

### Error: "Connection refused"
- Verifica firewall interno del servidor n8n
- Confirma que el puerto 5678 está expuesto
- Test directo: `curl http://IP_SERVIDOR:5678`

## Ventajas de esta configuración

1. **Sin contenedores extra**: No necesitas Caddy/Nginx
2. **Gestión centralizada**: Todos los certificados en pfSense
3. **Mayor seguridad**: Firewall empresarial
4. **Monitoreo integrado**: Logs y estadísticas en pfSense
5. **Multi-aplicación**: Puedes agregar más apps al mismo proxy

## Alternativa: Usar pfSense + Cloudflare

Si prefieres, puedes usar Cloudflare como CDN/Proxy:

1. Apunta tu dominio a Cloudflare
2. En Cloudflare, apunta a la IP de pfSense
3. Activa "Full (strict)" SSL en Cloudflare
4. Beneficios: CDN, DDoS protection, analytics

## Resumen de puertos

| Servicio | Puerto | Tipo | Ubicación |
|----------|--------|------|-----------|
| HTTPS | 443 | TCP | pfSense (WAN) |
| HTTP | 80 | TCP | pfSense (WAN) |
| n8n | 5678 | TCP | Servidor interno |
| PostgreSQL | 5432 | TCP | Interno (no expuesto) |
| Redis | 6379 | TCP | Interno (no expuesto) |