# Use the latest Ubuntu as the base image
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /home/liam/dotfiles
WORKDIR /home/liam/dotfiles
COPY . /home/liam/dotfiles
RUN ls

RUN chmod +x bootstrap-ubuntu.sh && ./bootstrap-ubuntu.sh
USER liam
CMD ["/bin/zsh"]
