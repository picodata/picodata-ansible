#!/bin/bash

VMID=$1
PHASE=$2

if [ "$PHASE" = "post-start" ]; then

    pct exec $VMID -- sh -c '
        mkdir -p /etc/netplan
        cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
    '

    pct exec $VMID -- netplan apply

    pct exec $VMID -- sh -c 'echo "root:TemporarySecurePassword123" | chpasswd'

    SSH_KEY=$(grep -E '^#ssh-ed25519' /etc/pve/lxc/${VMID}.conf | sed 's/^#//')

    if [ ! -z "$SSH_KEY" ]; then
        pct exec $VMID -- sh -c "
            mkdir -p /root/.ssh
            chmod 700 /root/.ssh
            echo '$SSH_KEY' > /root/.ssh/authorized_keys
            chmod 600 /root/.ssh/authorized_keys
        "
    fi
    
    echo "=== All done ==="
fi

exit 0
