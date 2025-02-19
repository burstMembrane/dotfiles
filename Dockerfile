# Use the latest Ubuntu as the base image
FROM ubuntu:latest

# Set noninteractive mode for apt to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install the necessary packages
COPY ./bootstrap-ubuntu.sh /bootstrap.sh

# Make the script executable and run it
RUN chmod +x /bootstrap.sh && ./bootstrap.sh
# Switch to zsh for testing
USER liam

CMD ["/bin/zsh"]
