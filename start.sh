#!/bin/sh
set -eu

# Required secrets/config supplied by Back4app environment variables.
: "${PGSTORE_DSN:?PGSTORE_DSN is required}"
: "${PROXY_API_KEY:?PROXY_API_KEY is required}"
: "${MANAGEMENT_PASSWORD:?MANAGEMENT_PASSWORD is required}"

# Keep the API key easy to quote safely in YAML.
case "$PROXY_API_KEY" in
  *[!A-Za-z0-9._-]*)
    echo "ERROR: PROXY_API_KEY may contain only A-Z, a-z, 0-9, dot, underscore, and hyphen." >&2
    exit 1
    ;;
esac

export PGSTORE_SCHEMA="${PGSTORE_SCHEMA:-public}"
export PGSTORE_LOCAL_PATH="${PGSTORE_LOCAL_PATH:-/tmp/cpa}"

# CLIProxyAPI's native Postgres store uses:
#   $PGSTORE_LOCAL_PATH/pgstore/config/config.yaml
# as its local spool. If the database is empty, it imports this file into Postgres.
# If the database already has a config, CLIProxyAPI overwrites this local copy
# with the database copy during bootstrap.
CONFIG_DIR="$PGSTORE_LOCAL_PATH/pgstore/config"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  umask 077
  cat > "$CONFIG_FILE" <<EOF
host: "0.0.0.0"
port: 8317

tls:
  enable: false
  cert: ""
  key: ""

remote-management:
  allow-remote: false
  secret-key: ""
  disable-control-panel: false

auth-dir: "$PGSTORE_LOCAL_PATH/pgstore/auths"

api-keys:
  - "$PROXY_API_KEY"

debug: false
logging-to-file: false
EOF
fi

# MANAGEMENT_PASSWORD is handled natively by CLIProxyAPI and enables authenticated
# remote management without putting the management secret in the config file.
exec /CLIProxyAPI/CLIProxyAPI
