FROM alpine

# Update the system and install MariaDB
RUN apk update
RUN apk add --no-cache bash  vim 
RUN apk add --no-cache mariadb mariadb-client


WORKDIR /etc/my.cnf.d

EXPOSE 3306

# Entrypoint for certbot 
CMD ["bash", "-c", \
    "mariadbd --user=root --console && sleep infinty"]