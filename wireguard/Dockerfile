FROM alpine 

# Update apk software lists 
RUN apk update 


# Install dependencies 
RUN apk add --no-cache bash 
RUN apk add --no-cache iptables  ip6tables 
RUN apk add --no-cache wireguard-tools-wg-quick 

# Set working directory 
WORKDIR /etc/wireguard 

# Entrypoint for wireguard  
ENTRYPOINT ["wg-quick"]

