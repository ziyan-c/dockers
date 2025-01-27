#!/bin/bash 

# Path to the MariaDB data directory
DATA_DIR="/var/lib/docker/volumes/mariadb/var/lib/mysql"
INFO_PRIVATE="/var/lib/docker/volumes/mariadb/info.private"

# Extract the top-level domain name from info.private
if [[ -f $INFO_PRIVATE ]]; then
    TOP_LEVEL_DOMAIN_NAME=$(grep '^top_level_domain_name=' "$INFO_PRIVATE" | cut -d'=' -f2-)
else
    echo "Error: info.private not provided"
    exit 1
fi

# Build the Docker image
docker build -t ziyan1c/mariadb .

# Check if the data directory exists
if [[ ! -d "$DATA_DIR" ]]; then
    echo "Data directory does not exist. Preparing to initialize MariaDB..."

    # Create the MariaDB configuration directory
    mkdir -p /var/lib/docker/volumes/mariadb/etc/my.cnf.d

    # Create the MariaDB configuration file
    cat > /var/lib/docker/volumes/mariadb/etc/my.cnf.d/mariadb-server.cnf <<EOF
# MariaDB Configuration
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
    echo "Generated root password: $ROOT_PASSWORD"

    # Run the MariaDB container temporarily to initialize the data directory
    docker run --rm -it \
        -v /var/lib/docker/volumes/mariadb/etc/my.cnf.d:/etc/my.cnf.d \
        -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
        -v $DATA_DIR:/var/lib/mysql \
        ziyan1c/mariadb \
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    echo "MariaDB data directory initialized."

    # Start the MariaDB container temporarily to configure root privileges
    docker run -d -it --rm \
        -v /var/lib/docker/volumes/mariadb/etc/my.cnf.d:/etc/my.cnf.d \
        -v /var/lib/docker/volumes/certbot/etc/letsencrypt:/etc/letsencrypt \
        -v $DATA_DIR:/var/lib/mysql \
        -p 3306:3306 \
        --name mariadb-init \
        ziyan1c/mariadb

    # Wait for MariaDB to start
    echo "Waiting for MariaDB to start..."
    sleep 10

    # Configure root user privileges
    echo "Granting all privileges to root@%..."
    docker exec mariadb-init mariadb -u root <<EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ROOT_PASSWORD');
CREATE USER 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
DROP USER 'root'@'localhost';
FLUSH PRIVILEGES;
EOF

    echo "Root user privileges granted to root@%."

    # Stop and remove the temporary container
    docker stop mariadb-init
    docker rm mariadb-init
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

if [[ -n $ROOT_PASSWORD ]]; then
    echo "MariaDB is up and running. The root password is: $ROOT_PASSWORD"
fi
