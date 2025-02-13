FROM alpine

# Update the system 
RUN apk update
RUN apk add --no-cache bash  vim  wget 


WORKDIR /usr/local

# Install golang 
RUN wget  https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
RUN tar -C /usr/local  -xf  go1.24.0.linux-amd64.tar.gz

# Add Go binary to PATH 
RUN echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile 
ENV PATH=$PATH:/usr/local/go/bin 


# Not complete 
CMD ["bash", "-c", \
    "go run . && \
    sleep infinty"]