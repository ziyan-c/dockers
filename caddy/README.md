# caddy 

## Dockerfile 
build from Alpine 

## caddy.sh 
JOBS 
1. Read from info.private 
2. Write to Caddyfile 
3. Build and run docker 

## info.private
```text
# Top-level domain for redirection
top_level_domain=example.com

# Server-specific information
server_domain=server.example.com
server_cert=/etc/ssl/domain/a.pem
server_key=/etc/ssl/domain/a.key

# Reverse proxy configuration
reverse_proxy_ip=
reverse_proxy_port=
```