#!/bin/bash 

# JOBS 
# 1. Read from info.private 
# 2. if Caffyfile not provided
#   generate according to info.private 
# else 
#   use the provided Caddyfile directly 
# 3. Build and run docker 


INFO_PRIVATE="/var/lib/docker/volumes/caddy/info.private"

if [[ ! -f $INFO_PRIVATE ]]; then 
    echo "Error: info.private does not exist"
    exit 1
fi

# 1
# Read server info from info.private only when it does exist 
TOP_LEVEL_DOMAIN=$(grep "^top_level_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_DOMAIN=$(grep "^server_domain=" "$INFO_PRIVATE" | cut -d'=' -f2-)

SERVER_CERT=$(grep "^server_cert=" "$INFO_PRIVATE" | cut -d'=' -f2-)
SERVER_KEY=$(grep "^server_key=" "$INFO_PRIVATE" | cut -d'=' -f2-)

REVERSE_PROXY_IP=$(grep "^reverse_proxy_ip=" "$INFO_PRIVATE" | cut -d'=' -f2-)
REVERSE_PROXY_PORT=$(grep "^reverse_proxy_port=" "$INFO_PRIVATE" | cut -d'=' -f2-)

if [[ ! -f "/var/lib/docker/volumes/caddy/etc/ssl/$TOP_LEVEL_DOMAIN/cf.pem" ]]; then 
    echo "Error: ssl certificate does not exist"
    exit 1
fi 
if [[ ! -f "/var/lib/docker/volumes/caddy/etc/ssl/$TOP_LEVEL_DOMAIN/cf.key" ]]; then 
    echo "Error: ssl certificate does not exist"
    exit 1
fi 

# 2
# Caddyfile not provided 
if [[ ! -f /var/lib/docker/volumes/caddy/etc/caddy/Caddyfile ]]; then 
    # Initialize the Caddyfile
    mkdir -p /var/lib/docker/volumes/caddy/etc/caddy
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
fi


# 3
# build and run docker 
docker build -t ziyan1c/caddy .

docker run -d -it \
    -v /var/lib/docker/volumes/caddy/etc/caddy:/etc/caddy \
    -v /var/lib/docker/volumes/caddy/etc/ssl:/etc/ssl \
    -v /var/lib/docker/volumes/caddy/usr/share/caddy:/usr/share/caddy \
    -p 80:80 -p 443:443 \
    --network v2ray_network \
    --ip 192.168.10.10 \
    --restart always \
    --name caddy \
    ziyan1c/caddy 