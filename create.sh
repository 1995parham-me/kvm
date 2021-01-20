#!/bin/bash
# In The Name of God
# ========================================
# [] File Name : create.sh
#
# [] Creation Date : 19-01-2021
#
# [] Created By : Parham Alvani <parham.alvani@gmail.com>
# =======================================

read -p "USVM-#: " id
read -p "IP Address: " -i "192.168.73.0" -e ip


sed "s/usvm/usvm-$id/g" usvm.cfg > usvm-$id.cfg

mac_addr=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
cat > network-config-usvm-$id <<EOF
ethernets:
    eth0:
        addresses:
        - $ip/24
        dhcp4: false
        gateway4: 192.168.73.254
        match:
            macaddress: $mac_addr
        nameservers:
            addresses:
            - 185.51.200.2
            - 178.22.122.100
            - 192.168.73.254
        set-name: eth0
version: 2
EOF

cloud-localds -v --network-config=network-config-usvm-$id usvm-$id.qcow2 usvm-$id.cfg

rm usvm-$id.cfg
rm network-config-usvm-$id

qemu-img create -F qcow2 -b $HOME/kvm/base/Arch-Linux-x86_64-cloudimg-20210119.13892.qcow2 -f qcow2 $HOME/kvm/pool/usvm-$id.qcow2 20G

sudo virt-install --name usvm-$id \
  --virt-type kvm --memory 2048 --vcpus 2 \
  --boot hd,menu=on \
  --disk path=$HOME/kvm/seed/usvm-$id.qcow2,device=cdrom \
  --disk path=$HOME/kvm/pool/usvm-$id.qcow2,device=disk \
  --os-type Linux --os-variant archlinux \
  --network bridge=br0,model=virtio,mac=$mac_addr \
  --import
