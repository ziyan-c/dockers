#!/bin/bash

INFO_PRIVATE=/var/lib/docker/volumes/v2ray/info.private
USERS_JSON_PATH=/var/lib/docker/volumes/v2ray/etc/v2ray/users.json
CONFIG_JSON_PATH=/var/lib/docker/volumes/v2ray/etc/v2ray/config.json
LOG_FILE_PATH=/var/lib/docker/volumes/v2ray/var/log


# Ensure info.private exists
if [[ ! -f $INFO_PRIVATE ]]; then
    echo "Error: $INFO_PRIVATE not found."
    exit 1
fi

# Read configuration from info.private
DB_USERNAME=$(grep '^db_username=' "$INFO_PRIVATE" | cut -d'=' -f2-)
DB_PASSWORD=$(grep '^db_password=' "$INFO_PRIVATE" | cut -d'=' -f2-)
DB_SERVERNAME=$(grep '^db_servername=' "$INFO_PRIVATE" | cut -d'=' -f2-)
DB_NAME=$(grep '^db_dbname=' "$INFO_PRIVATE" | cut -d'=' -f2-)
DB_TABLE_NAME=$(grep '^db_table_name=' "$INFO_PRIVATE" | cut -d'=' -f2-)

VMESS_LISTEN=$(grep '^v2ray_vmess_listen=' "$INFO_PRIVATE" | cut -d'=' -f2-)
VMESS_PORT=$(grep '^v2ray_vmess_port=' "$INFO_PRIVATE" | cut -d'=' -f2-)

VLESS_LISTEN=$(grep '^v2ray_vless_listen=' "$INFO_PRIVATE" | cut -d'=' -f2-)
VLESS_PORT=$(grep '^v2ray_vless_port=' "$INFO_PRIVATE" | cut -d'=' -f2-)

API_LISTEN=$(grep '^v2ray_api_listen=' "$INFO_PRIVATE" | cut -d'=' -f2-)
API_PORT=$(grep '^v2ray_api_port=' "$INFO_PRIVATE" | cut -d'=' -f2-)

# Fetch user email and UUID from database using mariadb client
USERS=$(mariadb -h "$DB_SERVERNAME" -u"$DB_USERNAME" -p"$DB_PASSWORD" \
    -D"$DB_NAME" -e \
    "SELECT email, uuid FROM $DB_TABLE_NAME" -B -N)

if [[ -z "$USERS" ]]; then
    echo "Error: No users found in the database."
    exit 1
fi

# Generate users.json
mkdir -p "$(dirname "$USERS_JSON_PATH")"
cat <<EOF > "$USERS_JSON_PATH"
{
    "inbounds": [
        {
            "settings": {
                "clients": [
EOF

while IFS=$'\t' read -r email uuid; do
    cat <<EOF >> "$USERS_JSON_PATH"
                    {
                        "id": "$uuid",
                        "email": "$email"
                    },
EOF
done <<< "$USERS"

# Remove the trailing comma and close the JSON structure for vmess
sed -i '$ s/,$//' "$USERS_JSON_PATH"
cat <<EOF >> "$USERS_JSON_PATH"
                ]
            },
            "tag": "vmess"
        },
        {
            "settings": {
                "clients": [
EOF

# Generate user configuration for vless
while IFS=$'\t' read -r email uuid; do
    cat <<EOF >> "$USERS_JSON_PATH"
                    {
                        "id": "$uuid",
                        "email": "$email"
                    },
EOF
done <<< "$USERS"

# Remove the trailing comma and close the JSON structure for vless
sed -i '$ s/,$//' "$USERS_JSON_PATH"
cat <<EOF >> "$USERS_JSON_PATH"
                ]
            },
            "tag": "vless"
        }
    ]
}
EOF

# Generate config.json
# Execute only when $CONFIG_JSON_PATH does not exist
if [[ ! -f $CONFIG_JSON_PATH ]]; then 
    mkdir -p "$(dirname "$CONFIG_JSON_PATH")"
    cat <<EOF > "$CONFIG_JSON_PATH"
    {
        "inbounds": [
            {
                "tag": "vmess",
                "listen": "$VMESS_LISTEN",
                "port": $VMESS_PORT,
                "protocol": "vmess",
                "settings": { },
                "streamSettings": {
                    "network": "tcp"
                }
            },
            {
                "tag": "vless",
                "listen": "$VLESS_LISTEN",
                "port": $VLESS_PORT,
                "protocol": "vless",
                "settings": {
                    "decryption": "none"
                },
                "streamSettings": {
                    "network": "ws",
                    "wsSettings": {
                        "path": "/v2ray/"
                    }
                }
            },
            {
                "tag": "api",
                "listen": "$API_LISTEN",
                "port": $API_PORT,
                "protocol": "dokodemo-door",
                "settings": {
                    "address": "$API_LISTEN"
                }
            }
        ],
        "outbounds": [
            {
                "tag": "direct",
                "protocol": "freedom"
            }
        ],
        "log": {
            "access": "/var/log/v2ray/access.log",
            "error": "/var/log/v2ray/error.log",
            "loglevel": "warning"
        },
        "stats": {},
        "api": {
            "tag": "api",
            "services": [
                "StatsService"
            ]
        },
        "policy": {
            "levels": {
                "0": {
                    "statsUserUplink": true,
                    "statsUserDownlink": true
                }
            },
            "system": {}
        },
        "routing": {
            "rules": [
                {
                    "inboundTag": [
                        "api"
                    ],
                    "outboundTag": "api",
                    "type": "field"
                }
            ]
        }
    }
EOF

cat <<EOF
Configuration files have been written:
 - Users: $USERS_JSON_PATH
 - Config: $CONFIG_JSON_PATH
EOF

fi

docker build -t ziyan1c/v2ray . 

docker run -d -it \
    -v ${USERS_JSON_PATH}:/etc/v2ray/users.json \
    -v ${CONFIG_JSON_PATH}:/etc/v2ray/config.json \
    -v ${LOG_FILE_PATH}:/var/log/v2ray \
    -p ${VMESS_PORT}:${VMESS_PORT} \  
    --restart always \
    --ip 172.17.0.101 \
    --name v2ray \
    ziyan1c/v2ray 
