FROM alpine

# Update the system and install MariaDB
RUN apk update
RUN apk add --no-cache bash  vim 
RUN apk add --no-cache mariadb mariadb-client


WORKDIR /etc/caddy 

EXPOSE 3306

# Entrypoint for certbot 
ENTRYPOINT ["bash", "-c"]
CMD ["caddy start && sleep infinty"]