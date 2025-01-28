#!/bin/sh

## JOBS
# 1. Check if $INFO_PRIVATE exists
# if exists 
#   use the info 
# else 
#   create info for PC, Phone and tablet itself 
# 2. Create WireGuard configuration file 
# 3. Build docker ziyan1c/wireguard 
# 4. Run docker wireguard 

# Define variables
INFO_PRIVATE="/var/lib/docker/volumes/wireguard/info.private"
WIREGUARD_DIR="/var/lib/docker/volumes/wireguard/etc/wireguard"
CONFIG_FILE="$WIREGUARD_DIR/wg0.conf"
DOCKER_INTERFACE="eth0"
WIREGUARD_INTERFACE="wg0"
DOCKER_IMAGE="ziyan1c/wireguard"
CONTAINER_NAME="wireguard"

LISTEN_PORT=65530
ADDRESS_IPV4="10.0.1.1/24"
ADDRESS_IPV6="fc00::1:1/112"

# 1. Check if the $INFO_PRIVATE file exists
if [ -f "$INFO_PRIVATE" ]; then
    echo "Using existing private key and client configurations..."
    chmod 600 "$INFO_PRIVATE"
    . "$INFO_PRIVATE" # Source the private key and client details
else
    echo "Creating new WireGuard configuration..."
    docker volume create wireguard 
    PRIVATE_KEY=$(wg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

    PC_PRIVATE_KEY=$(wg genkey)
    PC_PUBLIC_KEY=$(echo "$PC_PRIVATE_KEY" | wg pubkey)

    PHONE_PRIVATE_KEY=$(wg genkey)
    PHONE_PUBLIC_KEY=$(echo "$PHONE_PRIVATE_KEY" | wg pubkey)

    TABLET_PRIVATE_KEY=$(wg genkey)
    TABLET_PUBLIC_KEY=$(echo "$TABLET_PRIVATE_KEY" | wg pubkey)

    cat > "$INFO_PRIVATE" <<EOF
private_key=$PRIVATE_KEY
public_key=$PUBLIC_KEY

pc_private_key=$PC_PRIVATE_KEY
pc_public_key=$PC_PUBLIC_KEY
pc_allowed_ips=10.0.1.2/32,fc00::1:2/128

phone_private_key=$PHONE_PRIVATE_KEY
phone_public_key=$PHONE_PUBLIC_KEY
phone_allowed_ips=10.0.1.3/32,fc00::1:3/128

tablet_private_key=$TABLET_PRIVATE_KEY
tablet_public_key=$TABLET_PUBLIC_KEY
tablet_allowed_ips=10.0.1.4/32,fc00::1:4/128

EOF

    chmod 600 "$INFO_PRIVATE"
    . "$INFO_PRIVATE" # Source the newly created file
fi

# 2. Create WireGuard configuration file only if it does not exist
if [ -f "$CONFIG_FILE" ]; then
    echo "$CONFIG_FILE already exists. Using existing configuration."
else
    echo "Creating WireGuard configuration file..."
    mkdir -p "$WIREGUARD_DIR"

    cat > "$CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $private_key
Address = $ADDRESS_IPV4, $ADDRESS_IPV6
ListenPort = $LISTEN_PORT

# pure iptables 
PostUp = iptables -I INPUT -p udp --dport $LISTEN_PORT -j ACCEPT && \
    iptables -I FORWARD -i $WIREGUARD_INTERFACE -o $DOCKER_INTERFACE -j ACCEPT && \
    iptables -I FORWARD -i $DOCKER_INTERFACE -o $WIREGUARD_INTERFACE -j ACCEPT && \
    iptables -t nat -A POSTROUTING -s $ADDRESS_IPV4 -o $DOCKER_INTERFACE -j MASQUERADE && \
    [ -e /proc/net/if_inet6 ] && ip6tables -t nat -A POSTROUTING -s $ADDRESS_IPV6 -o $DOCKER_INTERFACE -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport $LISTEN_PORT -j ACCEPT && \
    iptables -D FORWARD -i $WIREGUARD_INTERFACE -o $DOCKER_INTERFACE -j ACCEPT && \
    iptables -D FORWARD -i $DOCKER_INTERFACE -o $WIREGUARD_INTERFACE -j ACCEPT && \
    iptables -t nat -D POSTROUTING -s $ADDRESS_IPV4 -o $DOCKER_INTERFACE -j MASQUERADE && \
    [ -e /proc/net/if_inet6 ] && ip6tables -t nat -D POSTROUTING -s $ADDRESS_IPV6 -o $DOCKER_INTERFACE -j MASQUERADE

EOF

    echo "# Client configurations" >> "$CONFIG_FILE"
    while read -r line; do
        if [[ $line == *_private_key=* ]]; then
            CLIENT=$(echo "$line" | cut -d'_' -f1)
            PUBLIC_KEY=$(grep "^${CLIENT}_public_key=" "$INFO_PRIVATE" | cut -d'=' -f2-)
            ALLOWED_IPS=$(grep "^${CLIENT}_allowed_ips=" "$INFO_PRIVATE" | cut -d'=' -f2-)

            echo "# $CLIENT" >> "$CONFIG_FILE"
            echo "[Peer]" >> "$CONFIG_FILE"
            echo "PublicKey = $PUBLIC_KEY" >> "$CONFIG_FILE"
            echo "AllowedIPs = $ALLOWED_IPS" >> "$CONFIG_FILE"
            echo >> "$CONFIG_FILE"
        fi
    done < "$INFO_PRIVATE"

    chmod 600 "$CONFIG_FILE"
    echo "WireGuard configuration file created."
fi

# 3. Build Docker image
echo "Building Docker image..."
docker build -t "$DOCKER_IMAGE" .

# 4. Run WireGuard container

echo "Starting new WireGuard container..."
docker run -d -it \
    --name "$CONTAINER_NAME" \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv6.conf.all.forwarding=1 \
    -v "$WIREGUARD_DIR:/etc/wireguard" \
    -v "$CONFIG_FILE:/etc/wireguard/$WIREGUARD_INTERFACE.conf" \
    -p "$LISTEN_PORT:$LISTEN_PORT/udp" \
    --restart always \
    "$DOCKER_IMAGE"


echo "WireGuard setup completed successfully."
