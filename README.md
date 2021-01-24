# kvm

## Introduction

These scripts and materials use on the kvm nodes to create development virtual machines.
Machines that use Archlinux and historically named USVM.

## VM Networking
Default libvirt network is NAT, to have direct network we need to create a bridge with the server address instead of its default network card.
Example exists on repository,
