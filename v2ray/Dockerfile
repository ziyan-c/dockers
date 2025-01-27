FROM alpine

# Update the system and install MariaDB
RUN apk update
RUN apk add --no-cache bash  vim 
RUN apk add --no-cache v2ray 



WORKDIR /etc/v2ray


CMD ["bash", "-c", \
    "v2ray run && \
    sleep infinty"]