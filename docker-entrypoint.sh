#!/bin/bash
set -e

# Railway/Render provides PORT env, but Apache expects 80 - handle PORT
if [ -n "$PORT" ]; then
  echo "PORT=$PORT, configuring Apache to listen on $PORT"
  sed -i "s/Listen 80/Listen $PORT/" /etc/apache2/ports.conf
  sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$PORT>/" /etc/apache2/sites-available/000-default.conf
fi

# Generate config.inc.php from env if not exists or update DB settings
CONFIG_FILE="/var/www/html/config.inc.php"
TEMPLATE_FILE="/var/www/html/config.TEMPLATE.inc.php"

if [ ! -f "$CONFIG_FILE" ]; then
  cp "$TEMPLATE_FILE" "$CONFIG_FILE"
  echo "Created config.inc.php from template"
fi

# Helper to set config value via sed (simple, handles quoted and unquoted)
# IMPORTANT (OJS ConfigParser): quoted values are ALWAYS strings, unquoted
# On/Off/true/false become real booleans. Since HttpsPolicy does
# (bool)Config::getVar('security','force_ssl'), writing force_ssl = "Off"
# (quoted) makes it TRUTHY and causes an infinite redirectSSL() loop
# (Location identical to request URL) behind the Railway TLS proxy.
# So booleans and numbers are written UNQUOTED, real strings quoted.
set_config() {
  local section="$1"
  local key="$2"
  local value="$3"
  # Escape for sed
  local esc_value=$(printf '%s\n' "$value" | sed 's/[\/&]/\\&/g')
  local rendered
  case "$value" in
    On|Off|on|off|true|false|True|False|TRUE|FALSE)
      rendered="${esc_value}"
      ;;
    *)
      if printf '%s' "$value" | grep -qE '^[0-9]+$'; then
        rendered="${esc_value}"
      else
        rendered="\"${esc_value}\""
      fi
      ;;
  esac
  # Try to replace existing line (with or without quotes)
  if grep -q "^\s*${key}\s*=" "$CONFIG_FILE"; then
    sed -i "s|^\s*${key}\s*=.*|${key} = ${rendered}|" "$CONFIG_FILE"
  else
    # Insert under section header if not found
    sed -i "/^\[${section}\]/a ${key} = ${rendered}" "$CONFIG_FILE"
  fi
}

# Base URL - Railway provides RAILWAY_PUBLIC_DOMAIN, Render provides RENDER_EXTERNAL_HOSTNAME
if [ -n "$OJS_BASE_URL" ]; then
  set_config "general" "base_url" "$OJS_BASE_URL"
elif [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  set_config "general" "base_url" "https://${RAILWAY_PUBLIC_DOMAIN}"
elif [ -n "$RENDER_EXTERNAL_HOSTNAME" ]; then
  set_config "general" "base_url" "https://${RENDER_EXTERNAL_HOSTNAME}"
fi

# Database from env (support DATABASE_URL or separate vars)
if [ -n "$DATABASE_URL" ]; then
  # Parse mysql://user:pass@host:port/dbname
  DB_USER=$(echo $DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')
  DB_PASS=$(echo $DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
  DB_HOST=$(echo $DATABASE_URL | sed -n 's|.*@\([^:/]*\).*|\1|p')
  DB_PORT=$(echo $DATABASE_URL | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
  DB_NAME=$(echo $DATABASE_URL | sed -n 's|.*/\([^?]*\).*|\1|p')
  [ -n "$DB_HOST" ] && set_config "database" "host" "$DB_HOST"
  [ -n "$DB_USER" ] && set_config "database" "username" "$DB_USER"
  [ -n "$DB_PASS" ] && set_config "database" "password" "$DB_PASS"
  [ -n "$DB_NAME" ] && set_config "database" "name" "$DB_NAME"
  [ -n "$DB_PORT" ] && set_config "database" "port" "$DB_PORT"
else
  [ -n "$DATABASE_HOST" ] && set_config "database" "host" "$DATABASE_HOST"
  [ -n "$DATABASE_USER" ] && set_config "database" "username" "$DATABASE_USER"
  [ -n "$DATABASE_PASSWORD" ] && set_config "database" "password" "$DATABASE_PASSWORD"
  [ -n "$DATABASE_NAME" ] && set_config "database" "name" "$DATABASE_NAME"
  [ -n "$DATABASE_PORT" ] && set_config "database" "port" "$DATABASE_PORT"
fi

# Security secrets
[ -n "$OJS_API_SECRET" ] && set_config "security" "api_key_secret" "$OJS_API_SECRET"
[ -n "$OJS_SALT" ] && set_config "security" "salt" "$OJS_SALT"

# Files dir - use Railway/Render disk or /tmp
if [ -n "$OJS_FILES_DIR" ]; then
  set_config "files" "files_dir" "$OJS_FILES_DIR"
else
  # Default to /var/www/ojs-files which is created in Dockerfile
  set_config "files" "files_dir" "/var/www/ojs-files"
  set_config "files" "public_files_dir" "/var/www/ojs-files"
fi

# Installed flag - DB is already seeded (ojs_epc with epc journal), so mark On
set_config "general" "installed" "On"
# Allow host - Railway or Render
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  set_config "general" "allowed_hosts" "[\"${RAILWAY_PUBLIC_DOMAIN}\"]"
elif [ -n "$RENDER_EXTERNAL_HOSTNAME" ]; then
  set_config "general" "allowed_hosts" "[\"${RENDER_EXTERNAL_HOSTNAME}\"]"
else
  set_config "general" "allowed_hosts" '["epc-ojs-production.up.railway.app"]'
fi
# Force SSL off - let Cloudflare/Railway handle https
set_config "security" "force_ssl" "Off"
set_config "security" "force_login_ssl" "Off"
# Trust proxy On for Railway/Render X-Forwarded-Proto
set_config "general" "trust_x_forwarded_for" "On"
# Disable IP check for sessions (proxy IP changes)
set_config "security" "session_check_ip" "Off"
# Ensure base_url is https for Railway if not already set via OJS_BASE_URL
if ! grep -q 'base_url = "https://' "$CONFIG_FILE"; then
  if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    set_config "general" "base_url" "https://${RAILWAY_PUBLIC_DOMAIN}"
  fi
fi
# App key - generate if empty (required for encryption)
if ! grep -q 'app_key = "base64:' "$CONFIG_FILE"; then
  if command -v openssl >/dev/null 2>&1; then
    RAND_KEY=$(openssl rand -base64 32 | tr -d '\n')
  else
    RAND_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '\n')
  fi
  set_config "general" "app_key" "base64:${RAND_KEY}"
  echo "Generated app_key"
fi

# Ensure permissions
chown -R www-data:www-data /var/www/html/cache /var/www/html/public /var/www/ojs-files 2>/dev/null || true
chmod -R 755 /var/www/html/cache 2>/dev/null || true

# Clear cache
rm -rf /var/www/html/cache/*.php /var/www/html/cache/t_cache/* 2>/dev/null || true

# Apache MPM guard - mod_php requires exactly one MPM (prefork).
# Re-enforce at container start so a stale image layer can never crash Apache
# with "AH00534: More than one MPM loaded".
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf
a2enmod mpm_prefork >/dev/null 2>&1 || true

echo "OJS config prepared. base_url=$(grep -m1 'base_url' $CONFIG_FILE)"

exec "$@"
