#!/bin/bash

# Variables
CADDY_VOLUME="/var/lib/docker/volumes/caddy"
INFO_PRIVATE="$CADDY_VOLUME/info.private"

# Check for info.private
if [[ ! -f $INFO_PRIVATE ]]; then
    echo "Error: info.private does not exist"
    exit 1
fi

# Read server info from info.private
TOP_LEVEL_DOMAIN=$(grep "^top_level_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_DOMAIN=$(grep "^server_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_CERT=$(grep "^server_cert=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_KEY=$(grep "^server_key=" "$INFO_PRIVATE" | cut -d'=' -f2-)
REVERSE_PROXY_IP=$(grep "^reverse_proxy_ip=" "$INFO_PRIVATE" | cut -d'=' -f2-)
REVERSE_PROXY_PORT=$(grep "^reverse_proxy_port=" "$INFO_PRIVATE" | cut -d'=' -f2-)

# Check SSL files
if [[ ! -f "$CADDY_VOLUME/etc/ssl/$TOP_LEVEL_DOMAIN/cf.pem" || \
      ! -f "$CADDY_VOLUME/etc/ssl/$TOP_LEVEL_DOMAIN/cf.key" ]]; then
    echo "Error: SSL certificate files do not exist"
    exit 1
fi

# Check and generate Caddyfile if needed
if [[ ! -f "$CADDY_VOLUME/etc/caddy/Caddyfile" ]]; then
    echo "Generating Caddyfile..."
    mkdir -p "$CADDY_VOLUME/etc/caddy"
    cat > "$CADDY_VOLUME/etc/caddy/Caddyfile" <<EOF
    {
        auto_https disable_certs
        log {
            output discard
        }
    }

    $SERVER_DOMAIN {
        tls $SERVER_CERT $SERVER_KEY
        root * /usr/share/caddy
        file_server

        @websockets {
            path /v2ray/*
            header Connection Upgrade
            header Upgrade websocket
        }
        @not-websockets {
            not path /v2ray/*
        }
        reverse_proxy @websockets $REVERSE_PROXY_IP:$REVERSE_PROXY_PORT {
            header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
        }
        redir @not-websockets https://$TOP_LEVEL_DOMAIN permanent
    }
EOF
fi


docker build -t ziyan1c/caddy .

# Run Docker container
echo "Starting Docker container..."
docker run -d -it \
    -v "$CADDY_VOLUME/etc/caddy:/etc/caddy" \
    -v "$CADDY_VOLUME/etc/ssl:/etc/ssl" \
    -v "$CADDY_VOLUME/usr/share/caddy:/usr/share/caddy" \
    -p 80:80 -p 443:443 \
    --network v2ray_network \
    --ip 192.168.10.10 \
    --restart always \
    --name caddy \
    ziyan1c/caddy
