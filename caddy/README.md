# caddy 

## Prerequisites
Create new docker network 
```text
docker network create \
    --driver bridge \
    --subnet 192.168.10.0/24 \
    v2ray_network 
```

## Dockerfile 
build from Alpine 

## caddy.sh 
JOBS 
1. Read from info.private 
2. Write to Caddyfile 
3. Build and run docker 
default ip address 172.17.0.100


## info.private
```text
# Top-level domain for redirection
top_level_domain=example.com

# Server-specific information
server_domain=server.example.com
server_cert=/etc/ssl/domain/cf.pem
server_key=/etc/ssl/domain/cf.key

# Reverse proxy configuration
reverse_proxy_ip=
reverse_proxy_port=
```