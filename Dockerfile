# Use the latest Ubuntu as the base image
FROM ubuntu:latest

# Set noninteractive mode for apt to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Define a build argument for Docker
ARG DOCKER=false

# Set the DOCKER environment variable
ENV DOCKER=true

# setup the liam user and put in the 
# sudo group
# expose 443 for the web server
EXPOSE 443

COPY ./bootstrap-ubuntu.sh /bootstrap.sh

# Make the script executable and run it
RUN chmod +x /bootstrap.sh && DOCKER=true ./bootstrap.sh
USER liam
# Switch to zsh for testing
CMD ["/bin/zsh"]
