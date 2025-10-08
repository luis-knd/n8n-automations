# n8n Stack (Postgres)

![n8n self-hosted](https://img.shields.io/badge/n8n-self--hosted-orange?logo=n8n)
![Docker Compose](https://img.shields.io/badge/docker-compose-2496ED?logo=docker&logoColor=white)
![Postgres](https://img.shields.io/badge/database-PostgreSQL-336791?logo=postgresql&logoColor=white)

Infraestructura local de **n8n** apoyada en **Postgres** y Docker Compose. Está pensada para tener nombres explícitos (`n8n_app`, `n8n_postgres`, red `n8n_backend`) y volúmenes dedicados (`n8n_app_data`, `n8n_pg_data`) que facilitan mantenimiento, copias de seguridad y troubleshooting.

> **Tip:** Ideal para entornos de desarrollo, pruebas o despliegues autoalojados con control total sobre credenciales y backups.

---

## Tabla de contenidos

- [Características Clave](#características-clave)
- [Requisitos](#requisitos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Puesta en Marcha Rápida](#puesta-en-marcha-rápida)
- [Variables de Entorno Esenciales](#variables-de-entorno-esenciales)
- [Seguridad Recomendada](#seguridad-recomendada)
- [Copias de Seguridad y Restauración](#copias-de-seguridad-y-restauración)
- [Actualizaciones](#actualizaciones)
- [Troubleshooting](#troubleshooting)
- [Decisiones de Diseño](#decisiones-de-diseño)
- [Recursos Útiles](#recursos-útiles)

---

## Características Clave

- **Stack reproducible** con versiones fijas de imágenes Docker.
- **Claves y secretos separados** fuera del `docker-compose.yml`.
- **Healthchecks** incorporados para garantizar orden de arranque.
- **Scripts auxiliares** para generar claves y gestionar secretos.

---

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) o Docker Engine ≥ 20.x
- Docker Compose ≥ 2.x

---

## Estructura del Proyecto

```
/media/Proyectos/personales/Automations/n8n
├── docker-compose.yml
├── .env
├── .env.example
├── secrets/
│   └── postgres_password.txt
├── scripts/
│   └── generate_encryption_key.sh
├── backups/
│   └── .gitkeep
└── README.md
```

---

## Puesta en Marcha Rápida

1. **Genera una clave para `N8N_ENCRYPTION_KEY`:**
   ```bash
   ./scripts/generate_encryption_key.sh
   ```

2. **Crea tu entorno local a partir del ejemplo:**
   ```bash
   cp -p .env.example .env
   ```

3. **Protege los archivos sensibles:**
   ```bash
   chmod 600 .env secrets/postgres_password.txt
   ```

4. **Levanta el stack:**
   ```bash
   docker compose up -d
   ```

5. **Verifica salud y logs:**
   ```bash
   docker compose ps
   docker logs -f n8n_app
   ```

UI disponible en `http://localhost:6588`.

---

## Variables de Entorno Esenciales

- `N8N_ENCRYPTION_KEY`: clave maestra para credenciales cifradas. **No la cambies una vez en producción.**
- `POSTGRES_PASSWORD_FILE`: apunta a `./secrets/postgres_password.txt` por defecto.
- `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD`: credenciales HTTP básicas opcionales.
- `N8N_HOST`, `N8N_PROTOCOL`, `WEBHOOK_URL`: definen URL pública detrás de un proxy inverso.
- `TZ`: timezone del servidor (útil para logs y cron jobs).

> **Recuerda:** completa siempre `.env` antes de iniciar el stack.

---

## Seguridad Recomendada

- **TLS obligatorio** si expones el servicio: configura un proxy (Traefik, Caddy, Nginx) con certificado válido.
- Establece:
  - `N8N_PROTOCOL=https`
  - `N8N_HOST=tu-dominio`
  - `WEBHOOK_URL=https://tu-dominio`
  - `N8N_SECURE_COOKIE=true`
- Mantén el archivo `secrets/postgres_password.txt` fuera de control de versiones y con permisos restrictivos.

---

## Copias de Seguridad y Restauración

### Base de datos (Postgres)

```bash
docker exec -t n8n_postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  > "./backups/$(date +'%Y%m%d-%H%M%S')-n8n.sql"
```

### Volúmenes clave

- `n8n_pg_data`: datos de Postgres.
- `n8n_app_data`: archivos internos de n8n (workflows, assets, binarios).

### Restauración rápida

```bash
cat backups/FECHA-n8n.sql | docker exec -i n8n_postgres \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

> **Sugerencia:** automatiza backups con cron + rotación y súbelos a almacenamiento seguro.

---

## Actualizaciones

1. Cambia la etiqueta `n8nio/n8n:X.Y.Z` en `docker-compose.yml` a la versión deseada.
2. Realiza backup completo (DB + `n8n_app_data`).
3. Ejecuta `docker compose pull && docker compose up -d`.
4. Observa `docker logs -f n8n_app` para confirmar migraciones exitosas.

---

## Troubleshooting

- **n8n arranca antes que Postgres:** revisa `docker logs n8n_postgres`. El servicio espera `service_healthy`; si falla, valida credenciales y salud del contenedor.
- **Problemas de login / credenciales inválidas:** revisa `N8N_BASIC_AUTH_*` y confirma que `N8N_ENCRYPTION_KEY` no haya cambiado.
- **Webhooks fallan en producción:** verifica `WEBHOOK_URL`, protocolo/host real tras el proxy y activa `N8N_SECURE_COOKIE=true` en HTTPS.
- **Errores por falta de permisos:** comprueba permisos de `.env` y `secrets/` (600 recomendado).

---

## Decisiones de Diseño

- **Versiones fijadas** para garantizar despliegues reproducibles.
- **Separación de secretos** para evitar credenciales en texto plano en `docker-compose.yml`.
- **Healthchecks personalizados** que facilitan detección temprana de fallos.
- **Naming convention `n8n_*`** para identificar fácilmente recursos en Docker.

---

## Recursos Útiles

- [Documentación oficial de n8n](https://docs.n8n.io/)
- [Configurar TLS con Traefik](https://doc.traefik.io/traefik/)
- [PostgreSQL Backups Best Practices](https://www.postgresql.org/docs/current/backup.html)
