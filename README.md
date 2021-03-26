# kvm

## Introduction

These scripts and materials use on the kvm nodes to create virtual machines.
Virtual machines use Archlinux or Ubuntu Server which are historically named USVM.

## Cloud Init

In order to create virtual machines with pre-defined configuration we use cloud-init.
You must write the configuration into a file and then create an image based on it.
After that you mount this image as a CD/DVD with the cloud image of your chosen operating system.
actually cloud images are disks so you need to expand them for using them but a btter way is to create a linked image with a bigger size for your virtual machine.

## VM Networking

Default libvirt network is NAT, to have direct network we need to create a bridge with the server address instead of its default network card.
Example with [netplan](https://netplan.io/) exists on repository.
