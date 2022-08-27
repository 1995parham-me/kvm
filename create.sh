#!/bin/bash

set -eu

# shellcheck disable=1004
echo '
   ____  _  ___   ___  ____                   _
  / __ \/ |/ _ \ / _ \| ___| _ __   __ _ _ __| |__   __ _ _ __ ___
 / / _` | | (_) | (_) |___ \| |_ \ / _| | |__| |_ \ / _| | |_ | _ \
| | (_| | |\__, |\__, |___) | |_) | (_| | |  | | | | (_| | | | | | |
 \ \__,_|_|  /_/   /_/|____/| .__/ \__,_|_|  |_| |_|\__,_|_| |_| |_|
  \____/                    |_|
'

# print log message with following format
# [module] message
message() {
	module=$1
	shift

	echo -e "\e[38;5;46m[$module] \e[38;5;202m$*\e[39m"
}

# reads usvm identification from user. identification must be an integer
read -r -p "usvm-#: " id
if [[ ! "$id" =~ ^[0-9]+$ ]]; then
	message "cloud-init" "usvm id must be an integer"
	exit
fi

# reads ip address from user.
# http://www.ipregex.com/
dhcp=1
read -r -p "ip address [use - for dhcp]: " -i "192.168.73.0" -e ip
if [[ "$ip" == "-" ]]; then
	dhcp=0
	message "cloud-init" "use dhcp instead of ip address"
elif [[ ! "$ip" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
	message "cloud-init" "$ip ip addresses isn't valid"
	exit
fi

# reads subnet mask
if [ $dhcp -eq 1 ]; then
	read -r -p "subnet mask: " -i "24" -e netmask
	if [[ ! $netmask -lt 32 ]] || [[ ! $netmask -gt 0 ]]; then
		message "cloud-init" "$netmask network mask isn't valid"
		exit
	fi
fi

# reads gateway/dns address
if [ $dhcp -eq 1 ]; then
	read -r -p 'gateway: ' -i '192.168.73.254' -e gateway
	if [[ ! "$gateway" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
		message "cloud-init" "$gateway ip addresses isn't valid"
		exit
	fi
fi

# reads parham/root password
read -r -p 'password: ' -e password

sed "s/usvm/usvm-$id/g" usvm.cfg >"usvm-$id.cfg"
sed "s/secret/$password/g" -i "usvm-$id.cfg"

# generates a random mac address
mac_addr=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

if [ $dhcp -eq 0 ]; then
	cat >"network-config-usvm-$id" <<EOF
ethernets:
    eth0:
        dhcp4: true
        match:
            macaddress: $mac_addr
        set-name: eth0
version: 2
EOF
else
	cat >"network-config-usvm-$id" <<EOF
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
fi

message "cloud-init" "generate configuration image that must be mount as cd/dvd into a virtual machine"
cloud-localds -v --network-config="network-config-usvm-$id" "usvm-$id.qcow2" "usvm-$id.cfg"

rm "usvm-$id.cfg"
rm "network-config-usvm-$id"

read -r -p "you have the configuration image, do you want to continue? (Y/n)" -n 1 confirm
echo
if [[ $confirm != "Y" ]]; then
	exit
fi

read -r -p 'disk size: ' -i '20G' -e size
read -r -p 'memory: ' -i '2048' -e memory
read -r -p 'vcpus: ' -i '2' -e vcpus

read -r -p 'os: ' -i 'ubuntu' -e os
case $os in
ubuntu)
	message "virt" "create ubuntu20.04 image based on $HOME/kvm/base/focal-server-cloudimg-amd64.img in $HOME/kvm/pool/usvm-$id.qcow2"
	qemu-img create -F qcow2 -b "$HOME/kvm/base/focal-server-cloudimg-amd64.img" -f qcow2 "$HOME/kvm/pool/usvm-$id.qcow2" "$size"
	os_variant=ubuntu20.04
	;;
arch)
	image=$(find "$HOME/kvm/base" -name 'Arch-Linux-x86_64-cloudimg-*.qcow2' | head -1)
	message "virt" "create archlinux image based on $image in $HOME/kvm/pool/usvm-$id.qcow2"
	qemu-img create -F qcow2 -b "$image" -f qcow2 "$HOME/kvm/pool/usvm-$id.qcow2" "$size"
	os_variant=archlinux

	message "virt" "please consider the locale.gen issue"
	;;
*)
	message "virt" "os must be arch or ubuntu"
	;;

esac

read -r -p "you have the image, do you want to continue? (Y/n)" -n 1 confirm
echo
if [[ $confirm != "Y" ]]; then
	exit
fi

read -r -p "bridge: " -i "br0" -e bridge

message "virt" "create $os_variant virtual machine which is named usvm-$id and attached to $bridge"

sudo virt-install --name "usvm-$id" \
	--virt-type kvm --memory "$memory" --vcpus "$vcpus" \
	--boot hd,menu=on \
	--disk "path=$HOME/kvm/seed/usvm-$id.qcow2,device=cdrom" \
	--disk "path=$HOME/kvm/pool/usvm-$id.qcow2,device=disk" \
	--os-type Linux --os-variant $os_variant \
	--network bridge="$bridge",model=virtio,mac="$mac_addr" \
	--import
