<h1 align="center"> KVM </h1>

<p align="center">
  <img alt="logo" src="./.github/assets/logo.png" />
</p>

## Introduction

I am utilizing **[KVM](https://www.redhat.com/en/topics/virtualization/what-is-KVM) with [libvirt](https://libvirt.org/)** for local virtualization.
The performance is satisfactory and aligns with my requirements. 

Setting up virtual machines (VMs) can be quite time-consuming. To streamline this process, I am employing **[Vagrant](https://www.vagrantup.com/)** to create and manage the VMs.

## Installation and Usage

To install and use this repository, execute the following command from [`dotfiles`](https://github.com/1995parham/dotfiles):

```bash
./start.sh kvm
```

## Up and Running

You can start your Linux virtual machine first by customizing the `usvm/config.json`,
and then you can start:

```bash
cd usvm || return

vagrant up
```
