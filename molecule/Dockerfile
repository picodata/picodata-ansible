FROM docker-proxy.binary.picodata.io/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y python3-pip wget openssh-client

COPY requirements.yml .

RUN pip install -r requirements.yml --break-system-packages

RUN ansible-galaxy collection install community.proxmox community.crypto community.general ansible.posix
