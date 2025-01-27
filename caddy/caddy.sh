#!/bin/bash 

# JOBS 
# 1. Read from info.private 
# 2. Write to Caddyfile 
# 3. Build and run docker 


INFO_PRIVATE="/var/lib/docker/volumes/caddy/info.private"

# 1
# Read server info from info.private
TOP_LEVEL_DOMAIN=$(grep "^top_level_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_DOMAIN=$(grep "^server_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)

SERVER_CERT=$(grep "^server_cert=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_KEY=$(grep "^server_key=" "$INFO_PRIVATE" | cut -d'=' -f2-)

REVERSE_PROXY_IP=$(grep "^reverse_proxy_ip=" "$INFO_PRIVATE" | cut -d'=' -f2-)
REVERSE_PROXY_PORT=$(grep "^reverse_proxy_port=" "$INFO_PRIVATE" | cut -d'=' -f2-)


# 2
# Initialize the Caddyfile
cat > /var/lib/docker/volumes/caddy/etc/caddy/Caddyfile <<EOF
# Global Option Block
{
    # Disable automatic certificate management
    auto_https disable_certs

    # Disable logging
    log {
        output discard
    }
}
EOF

# Add the server-specific Caddyfile configuration
cat >> /var/lib/docker/volumes/caddy/etc/caddy/Caddyfile <<EOF
$SERVER_DOMAIN {
    # Set custom ssl certificates
    tls $SERVER_CERT $SERVER_KEY

    # Set this path to your site's directory.
    root * /usr/share/caddy

    # Enable the static file server.
    file_server

    # Named matcher for websockets
    @websockets {
        path /v2ray/*
        header Connection Upgrade
        header Upgrade websocket
    }
    @not-websockets {
        not path /v2ray/*
    }
    # Another common task is to set up a reverse proxy:
    reverse_proxy @websockets $REVERSE_PROXY_IP:$REVERSE_PROXY_PORT {
        # Restore Client Original IP
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
    }

    # Redirect /*
    redir @not-websockets https://$TOP_LEVEL_DOMAIN permanent
}
EOF


# 3
# build and run docker 
docker build -t ziyan1c/caddy .

docker run -d -it \
    -v /var/lib/docker/volumes/caddy/etc/caddy:/etc/caddy \
    -v /var/lib/docker/volumes/caddy/etc/ssl:/etc/ssl \
    -v /var/lib/docker/volumes/caddy/usr/share/caddy:/usr/share/caddy \
    -p 80:80 -p 443:443 \
    --restart always \
    --name caddy \
    ziyan1c/caddy 