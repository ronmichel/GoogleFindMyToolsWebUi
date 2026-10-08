#!/usr/bin/env bash
set -e

# 1. Export Home Assistant Add-on options (/data/options.json) as environment variables
if [ -f /data/options.json ]; then
    eval "$(python3 -c '
import json, os, shlex
with open("/data/options.json") as f:
    opts = json.load(f)
mapping = {
    "http_user": "HTTP_USER",
    "http_password": "HTTP_PASSWORD",
    "secrets_encryption_key": "SECRETS_ENCRYPTION_KEY",
    "https_enabled": "HTTPS_ENABLED",
    "gfmt_tls_san": "GFMT_TLS_SAN",
}
for ha_key, env_key in mapping.items():
    val = opts.get(ha_key)
    if val is not None and val != "":
        if isinstance(val, bool):
            val = "true" if val else "false"
        print(f"export {env_key}={shlex.quote(str(val))}")
')"
fi

# 2. Ensure /run/gfmt-browser exists and allows binary execution for Chrome under Xvfb
mkdir -p /run/gfmt-browser
chmod 777 /run/gfmt-browser

# Check if /run is mounted with noexec; if so, symlink /run/gfmt-browser to an executable path
if mount | grep -E "on /run " | grep -q "noexec"; then
    echo "Notice: /run is mounted noexec. Redirecting /run/gfmt-browser to /var/tmp/gfmt-browser..."
    mkdir -p /var/tmp/gfmt-browser
    chmod 777 /var/tmp/gfmt-browser
    rm -rf /run/gfmt-browser
    ln -s /var/tmp/gfmt-browser /run/gfmt-browser
fi

# 3. Persist /firmware in /share/firmware if used
mkdir -p /share/firmware
if [ ! -e /firmware ]; then
    ln -s /share/firmware /firmware || true
fi

# 4. Hand off to the original container entrypoint/command
exec "$@"
