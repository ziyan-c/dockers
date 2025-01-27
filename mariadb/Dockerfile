FROM alpine

# Update the system and install MariaDB
RUN apk update
RUN apk add --no-cache bash  vim 
RUN apk add --no-cache mariadb mariadb-client

# Stupid Alpine error 
RUN mkdir /run/mysqld


WORKDIR /etc/my.cnf.d

EXPOSE 3306


CMD ["bash", "-c", \
    "mariadbd --user=root --console && \
    sleep infinty"]