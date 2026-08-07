FROM docker-proxy.binary.picodata.io/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    python3-pip \
    wget \
    openssh-client \
    curl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.yml .

RUN pip install -r requirements.yml --break-system-packages --no-cache-dir && \
    rm -rf /root/.cache/pip

RUN ansible-galaxy collection install community.proxmox community.crypto community.general ansible.posix && \
    rm -rf /root/.ansible/galaxy/cache
