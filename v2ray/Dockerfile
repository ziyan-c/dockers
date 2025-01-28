FROM alpine

# Update the system and install MariaDB
RUN apk update
RUN apk add --no-cache bash  vim 
RUN apk add --no-cache v2ray 

# Delete exsiting rules 
# Might be a backdoor
RUN rm -rf /etc/v2ray/*

# Create v2ray log files 
RUN mkdir -p /var/log/v2ray 
RUN touch /var/log/v2ray/access.log
RUN touch /var/log/v2ray/error.log

WORKDIR /etc/v2ray


CMD ["bash", "-c", \
    "v2ray run \
    -config /etc/v2ray/config.json \
    -config /etc/v2ray/users.json && \
    sleep infinty"]