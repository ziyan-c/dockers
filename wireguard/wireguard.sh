#!/bin/sh

## JOBS 
# 1. Check if $INFO_PRIVATE exists
# if exists 
#   use the info 
# else 
#   create info for PC, Phone and tablet itself 
# 2. Create wireguard configuration file 
# 3. Build docker ziyan1c/wireguard 
# 4. Run docker wireguard 


# Define variables
WIREGUARD_DIR="/var/lib/docker/volumes/wireguard"
INFO_PRIVATE="$WIREGUARD_DIR/info.private"
# info.private should contain:
# private_key=...
# pc_public_key=...
# pc_allowed_ips=...
# phone_public_key=...
# phone_allowed_ips=...
DOCKER_INTERFACE="eth0"
WIREGUARD_INTERFACE="wg0"
CONFIG_FILE="$WIREGUARD_DIR/$WIREGUARD_INTERFACE.conf"

LISTEN_PORT=65530
ADDRESS_IPV4="10.0.1.1/24"
ADDRESS_IPV6="fc00::1:1/112"

# 1
# Check if the $INFO_PRIVATE file exists
if [ -f "$INFO_PRIVATE" ]; then
    echo "Using existing private key..."
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


# 2 
# Create WireGuard configuration file
cat > "$CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $private_key
Address = $ADDRESS_IPV4, $ADDRESS_IPV6
ListenPort = $LISTEN_PORT

# firewalld is not working on Alpine 
# # firewalld 
# PostUp = firewall-cmd --permanent --add-port=65530/udp && \
#     firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=10.0.1.0/24 masquerade' && \
#     firewall-cmd --permanent --add-rich-rule='rule family=ipv6 source address=fc00::1:0/112 masquerade' && \
#     firewall-cmd --reload 
# PostDown = firewall-cmd --permanent --remove-port=65530/udp && \
#     firewall-cmd --permanent --remove-rich-rule='rule family=ipv4 source address=10.0.1.0/24 masquerade' && \
#     firewall-cmd --permanent --remove-rich-rule='rule family=ipv6 source address=fc00::1:0/112 masquerade' && \
#     firewall-cmd --reload

# # ufw with iptables 
# PostUp = ufw allow $LISTEN_PORT/udp && \
#     ufw reload \
#     ufw route allow in on $WIREGUARD_INTERFACE out on $DOCKER_INTERFACE && \
#     ufw route allow in on $DOCKER_INTERFACE out on $WIREGUARD_INTERFACE \
#     iptables -t nat -A POSTROUTING -s $ADDRESS_IPV4 -o $DOCKER_INTERFACE -j MASQUERADE \
#     ip6tables -t nat -A POSTROUTING -s $ADDRESS_IPV6 -o $DOCKER_INTERFACE -j MASQUERADE
# PostDown = ufw delete allow $LISTEN_PORT/udp && \
#     ufw reload \
#     ufw route delete allow in on $WIREGUARD_INTERFACE out on $DOCKER_INTERFACE && \
#     ufw route delete allow in on $DOCKER_INTERFACE out on $WIREGUARD_INTERFACE \
#     iptables -t nat -D POSTROUTING -s $ADDRESS_IPV4 -o $DOCKER_INTERFACE -j MASQUERADE \
#     ip6tables -t nat -D POSTROUTING -s $ADDRESS_IPV6 -o $DOCKER_INTERFACE -j MASQUERADE

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

# Client configurations
# PC configuration
[Peer]
PublicKey = $pc_public_key
AllowedIPs = $pc_allowed_ips

# Phone configuration
[Peer]
PublicKey = $phone_public_key
AllowedIPs = $phone_allowed_ips

# Tablet configuration
[Peer]
PublicKey = $tablet_public_key
AllowedIPs = $tablet_allowed_ips
EOF

chmod 600 "$CONFIG_FILE"

# Display the status
echo "WireGuard configuration completed."


# 3
# build docker ziyan1c/wireguard 
docker build -t ziyan1c/wireguard .


# 4.
# Run docker wireguard 
DOCKER_IMAGE="ziyan1c/wireguard"
CONTAINER_NAME="wireguard"

docker run -d \
    --name $CONTAINER_NAME \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv6.conf.all.forwarding=1 \
    -v "$WIREGUARD_DIR:/etc/wireguard" \
    -v "$CONFIG_FILE:/etc/wireguard/$WIREGUARD_INTERFACE.conf" \
    --restart unless-stopped \
    "$DOCKER_IMAGE"
