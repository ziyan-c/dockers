FROM alpine 

# Update apk software lists 
RUN apk update 

# Install dependencies 
RUN apk add --no-cache bash vim
RUN apk add --no-cache caddy 

WORKDIR /etc/caddy 


# Entrypoint for certbot 
ENTRYPOINT ["bash", "-c"]
CMD ["caddy start && sleep infinty"]