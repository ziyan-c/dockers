# Purpose 
Automating certbot working flow 

# Files 
## info.private 
```text
dns_cloudflare_api_token=<your cloudflare API token>
domains=example.com,*.example.com
email=<your email>
```

## Dockerfile 
Create certbot image based on Alpine.

## certbot.sh 
First preare the volume certbot in /var/lib/docker/volumes/certbot.
It will do:
1. Build the image certbot 
2. Run docker certbot 
3. Create a cron job to automatically update certificate every day at 8 AM
