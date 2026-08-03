#!/bin/bash

VMID=$1
PHASE=$2

if [ "$PHASE" == "post-start" ]; then

    MAX_ATTEMPTS=5
    ATTEMPT=1
    NETWORK_READY=false

    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if pct exec $VMID -- ping -c 1 -W 2 77.88.8.8 >/dev/null 2>&1; then
            NETWORK_READY=true
            break
        fi
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done

    if [ "$NETWORK_READY" = false ]; then
        echo "Hookscript: network is not ready."
        exit 1
    fi

    echo "Hookscript: Configuring SSH for CentOS 9 / AlmaLinux 9..."
    
    pct exec $VMID -- dnf install -y openssh-server
    
    pct exec $VMID -- sh -c 'mkdir -p /etc/ssh/sshd_config.d/ && echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitroot.conf'
    
    pct exec $VMID -- systemctl enable --now sshd

fi

exit 0
