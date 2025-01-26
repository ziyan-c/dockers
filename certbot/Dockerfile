FROM alpine 

# Update apk software lists 
RUN apk update 

# Install dependencies 
RUN apk add --no-cache bash 
RUN apk add --no-cache certbot cerbot-dns-cloudflare 

WORKDIR /etc/certbot 


# Entrypoint for certbot 
ENTRYPOINT ["certbot"]

