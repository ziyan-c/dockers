# Wireguard 

## Dockerfile 
Built on Alpine 

## wireguard.sh 
JOBS 
1. Check if $INFO_PRIVATE exists
if exists 
  use the info 
else 
  create info for PC, Phone and tablet itself 
2. Create wireguard configuration file 
3. Build docker ziyan1c/wireguard 
4. Run docker wireguard 


## info.private 
```text
private_key=
public_key=

pc_private_key=
pc_public_key=
pc_allowed_ips=10.0.1.2/32,fc00::1:2/128

phone_private_key=
phone_public_key=
phone_allowed_ips=10.0.1.3/32,fc00::1:3/128

tablet_private_key=
tablet_public_key=
tablet_allowed_ips=10.0.1.4/32,fc00::1:4/128
```