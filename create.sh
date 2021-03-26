#!/bin/bash
# In The Name of God
# ========================================
# [] File Name : create.sh
#
# [] Creation Date : 19-01-2021
#
# [] Created By : Parham Alvani <parham.alvani@gmail.com>
# =======================================
# https://stackoverflow.com/questions/3822621/how-to-exit-if-a-command-failed
set -e

# print log message with following format
# [module] message
message() {
	module=$1
	shift

	echo -e "\e[38;5;46m[$module] \e[38;5;202m$@\e[39m"
}

# reads usvm identification from user. identification must be an integer
read -p "usvm-#: " id
if [[ ! "$id" =~ ^[0-9]+$ ]]; then
	message "cloud-init" "usvm id must be an integer"
	exit
fi

# reads ip address from user.
# http://www.ipregex.com/
read -p "ip address: " -i "192.168.73.0" -e ip
if [[ ! "$ip" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
	message "cloud-init" "$ip ip addresses isn't valid"
	exit
fi

# reads subnet mask
read -p "subnet mask: " -i "24" -e netmask
if [[ ! $netmask -lt 32 ]] || [[ ! $netmask -gt 0 ]]; then
	message "cloud-init" "$netmask network mask isn't valid"
	exit
fi

# reads gateway/dns address
read -p 'gateway: ' -i '192.168.73.254' -e gateway
if [[ ! "$gateway" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
	message "cloud-init" "$gateway ip addresses isn't valid"
	exit
fi

sed "s/usvm/usvm-$id/g" usvm.cfg > usvm-$id.cfg

# generates a random mac address
mac_addr=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

cat > network-config-usvm-$id <<EOF
ethernets:
    eth0:
        addresses:
        - $ip/$netmask
        dhcp4: false
        gateway4: $gateway
        match:
            macaddress: $mac_addr
        nameservers:
            addresses:
            - $gateway
        set-name: eth0
version: 2
EOF

message "cloud-init" "generate configuration image that must be mount as cd/dvd into a virtual machine"
cloud-localds -v --network-config=network-config-usvm-$id usvm-$id.qcow2 usvm-$id.cfg

rm usvm-$id.cfg
rm network-config-usvm-$id

read -p "you have the configuration image, do you want to continue? (Y/n)" -n 1 confirm
if [[ $confirm != "Y" ]]; then
	exit
fi

read -p 'disk size: ' -i '20G' -e size
read -p 'memory: ' -i '2048' -e memory
read -p 'vcpus: ' -i '2' -e vcpus

read -p 'os: ' -i 'ubuntu' -e os
case $os in
	ubuntu)
		message "virt" "create ubuntu20.04 image based on $HOME/kvm/base/focal-server-cloudimg-amd64.img in $HOME/kvm/pool/usvm-$id.qcow2"
		qemu-img create -F qcow2 -b $HOME/kvm/base/focal-server-cloudimg-amd64.img -f qcow2 $HOME/kvm/pool/usvm-$id.qcow2 $size
		os_variant=ubuntu20.04
		;;
	arch)
		message "virt" "create archlinux image based on $HOME/kvm/base/Arch-Linux-x86_64-cloudimg-*.qcow2 in $HOME/kvm/pool/usvm-$id.qcow2"
		qemu-img create -F qcow2 -b $HOME/kvm/base/Arch-Linux-x86_64-cloudimg-*.qcow2 -f qcow2 $HOME/kvm/pool/usvm-$id.qcow2 $size
		os_variant=archlinux
		;;
	*)
		message  "virt" "os must be arch or ubuntu"
		;;

esac

read -p "you have the image, do you want to continue? (Y/n)" -n 1 confirm
if [[ $confirm != "Y" ]]; then
	exit
fi

message "virt" "create $os_variant virtual machine which is named usvm-$id and attached to br0"

sudo virt-install --name usvm-$id \
  --virt-type kvm --memory $memory --vcpus $vcpus \
  --boot hd,menu=on \
  --disk path=$HOME/kvm/seed/usvm-$id.qcow2,device=cdrom \
  --disk path=$HOME/kvm/pool/usvm-$id.qcow2,device=disk \
  --os-type Linux --os-variant $os_variant \
  --network bridge=br0,model=virtio,mac=$mac_addr \
  --import
