#!/bin/bash 

# JOBS 


# Path to the MariaDB data directory
DATA_DIR="/var/lib/docker/volumes/mariadb/var/lib/mysql"
INFO_PRIVATE="/var/lib/docker/volumes/mariadb/info.private"
TOP_LEVEL_DOMAIN_NAME=$(grep '^top_level_domain_name=' "$INFO_PRIVATE" | cut -d'=' -f2-)

if [[ ! -f $INFO_PRIVATE ]]; then 
    echo "Error: info.private not provided"
    exit 1
fi 

docker build -t ziyan1c/mariadb .

INITIALIZATION_REQUIRED=0
# Check if the data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "Data directory does not exist. Preparing to initialize MariaDB..."
    INITIALIZATION_REQUIRED=1

    # Create the MariaDB configuration directory
    mkdir -p /var/lib/docker/volumes/mariadb/etc/my.cnf.d

    # Create the MariaDB configuration file
    cat > /var/lib/docker/volumes/mariadb/etc/my.cnf.d/mariadb-server.cnf <<EOF
# this is only for the mysqld standalone daemon
[mysqld]
# General settings 
bind-address=0.0.0.0
port=3306

# Security 
ssl=on       # Enable SSL for secure connections 
ssl_cert=/etc/letsencrypt/live/$TOP_LEVEL_DOMAIN_NAME/fullchain.pem 
ssl_key=/etc/letsencrypt/live/$TOP_LEVEL_DOMAIN_NAME/privkey.pem 

EOF

    # Generate a random root password
    ROOT_PASSWORD=$(openssl rand -base64 20)
    #echo "Generated root password: $ROOT_PASSWORD"

    # Run the MariaDB container temporarily to initialize the data directory
    docker run --rm -it \
        -v /var/lib/docker/volumes/mariadb/etc/my.cnf.d:/etc/my.cnf.d \
        -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
        -v $DATA_DIR:/var/lib/mysql \
        ziyan1c/mariadb \
        mariadb-install-db --user=root --datadir=/var/lib/mysql

    echo "MariaDB data directory initialized."
fi

# Run the permanent MariaDB container
docker run -d -it \
    -v /var/lib/docker/volumes/mariadb/etc/my.cnf.d:/etc/my.cnf.d \
    -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
    -v $DATA_DIR:/var/lib/mysql \
    -p 3306:3306 \
    --restart always \
    --name mariadb \
    ziyan1c/mariadb


if [[ $INITIALIZATION_REQUIRED == 1 ]]; then 
    # Configure root user privileges
    echo "Granting all privileges to root@%..."

    docker exec mariadb -it \
    mariadb -u root <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';
    RENAME USER 'root'@'localhost' TO 'root'@'%';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF

    echo "Root user privileges granted to root@%."
fi


if [[ $ROOT_PASSWORD != '' ]]; then 
    echo "MariaDB is up and running. The root password is: $ROOT_PASSWORD"
fi 