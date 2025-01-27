# v2ray 

## Prerequisites
Create new docker network 
```text
docker network create \
    --driver bridge \
    --subnet 192.168.10.0/24 \
    v2ray_network 
```

## Dockerfile 
built on Alpine 

## v2ray.sh 


## info.private 
```text
v2ray_vmess_listen=0.0.0.0
v2ray_vmess_port=10086

v2ray_vless_listen=192.168.10.11
v2ray_vless_port=10087

v2ray_api_listen=192.168.10.11
v2ray_api_port=10088

db_username=
db_password=
db_servername=
db_dbname=
db_table_name=
```