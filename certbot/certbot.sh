#!/bin/bash

# Prerequisites:
# We have volume certbot/info.private prepared 

# Jobs
# 1. Build certbot image 
# 2. Run certbot to obtain initial certificate 
# 3. Create cron job to update certificate every day at 8 am 


# Extract info from info.private 
INFO_FILE=/var/lib/docker/volumes/certbot/info.private 
if [[ ! -f $INFO_FILE ]]; then 
    echo "Error: info.private not found"
    exit 1
fi 
chmod 600 $INFO_FILE

DOMAINS=$(grep '^domains=' "$INFO_FILE" | cut -d'=' -f2-)
EMAIL=$(grep '^email=' "$INFO_FILE" | cut -d'=' -f2-)

# Format domains into multiple -d options 
DOMAIN_ARGS=""
for domain in $(echo $DOMAINS | tr ',' ' '); do 
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done 


# 1. Build Docker image
docker build -t ziyan1c/certbot .

# 2. Run Docker certbot 
docker run --rm \
    -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
    -v /var/lib/docker/volumes/certbot/info.private:/etc/letsencrypt/info.private \
    ziyan1c/certbot certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/info.private \
    $DOMAIN_ARGS \
    --email $EMAIL \
    --non-interactive --agree-tos

# 3. Create a cron job to renew certificate daily at 8 AM
LOG_DIR="/var/lib/docker/volumes/certbot/var/log"
LOG_FILE="$LOG_DIR/certbot-renew.log"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

JOB="/usr/bin/docker run --rm \
    -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
    -v /var/lib/docker/volumes/certbot/info.private:/etc/letsencrypt/info.private \
    -v $LOG_DIR:/var/log \
    ziyan1c/certbot certbot renew \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/info.private >> /var/log/certbot-renew.log 2>&1"
CRON_JOB="0 8 * * *    $JOB"

if ! (crontab -l 2>/dev/null | grep -q "$JOB"); then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully"
else
    echo "Cron job already exists, skipping"
fi

# Limit logs 
cat > /etc/logrotate.d/certbot-renew <<EOF
/var/lib/docker/volumes/certbot/var/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

logrotate -v --force /etc/logrotate.d/certbot-renew

echo "Certbot setup completed. Logs are rotated daily with 7 backups."