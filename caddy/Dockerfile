FROM alpine 

# Update apk software lists 
RUN apk update 

# Install dependencies 
RUN apk add --no-cache bash vim
RUN apk add --no-cache caddy 

WORKDIR /etc/caddy 


# Entrypoint for certbot 
CMD ["bash", "-c", \
    "caddy start && sleep infinty"]