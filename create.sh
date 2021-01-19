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


if [ ! -f usvm-$id.qcow2 ]; then
        sed "s/usvm/usvm-$id/g" usvm.cfg > usvm-$id.cfg

        cloud-localds -v usvm-$id.qcow2 usvm-$id.cfg

        rm usvm-$id.cfg
fi

qemu-img create -F qcow2 -b $HOME/kvm/base/Arch-Linux-x86_64-cloudimg-20210119.13892.qcow2 -f qcow2 $HOME/kvm/pool/usvm-$id.qcow2 20G
