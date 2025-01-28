FROM alpine 

# Update apk software lists 
RUN apk update 


# Install dependencies 
RUN apk add --no-cache bash vim
RUN apk add --no-cache iptables  ip6tables 
RUN apk add --no-cache wireguard-tools  wireguard-tools-wg-quick   

# Set working directory 
WORKDIR /etc/wireguard 

# Entrypoint for wireguard  
CMD ["bash", "-c", \
    "wg-quick up wg0 && sleep infinity"]
