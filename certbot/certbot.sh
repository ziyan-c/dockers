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

#CLOUDFLARE_API_TOKEN=$(grep 'dns_cloudflare_api_token' "$INFO_FILE" | cut -d'=' -f2)
# Not necessary 
# It will get obtained automatically by certbot through the file info.private 

DOMAINS=$(grep 'domains' "$INFO_FILE" | cut -d'=' -f2)
EMAIL=$(grep 'email' "$INFO_FILE" | cut -d'=' -f2)

# Format domains into multiple -d options 
DOMAIN_ARGS=""
for domain in $(echo $DOMAINS | tr ',' ' '); do 
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done 


## JOBS

# 1
# Build dodkcer image 
docker build -t ziyan1c/certbot .


# 2
# Run docker certbot 
docker run --rm \
    -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
    -v /var/lib/docker/volumes/certbot/info.private:/etc/letsencrypt/info.private \
    ziyan1c/certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/info.private \
    $DOMAIN_ARGS \
    --email $EMAIL \
    --non-interactive --agree-tos 

# 3
# Create a cron job to renew certificate daily at 8 AM
JOB="/usr/bin/docker run --rm \
    -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
    -v /var/lib/docker/volumes/certbot/info.private:/etc/letsencrypt/info.private \
    ziyan1c/certbot renew \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/info.private"
CRON_JOB="0 8 * * *    $JOB"
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -