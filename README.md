<h1 align="center"> KVM </h1>

<p align="center">
  <img alt="logo" src="./.github/assets/logo.png" />
</p>

## Introduction

I am using [KVM](https://www.redhat.com/en/topics/virtualization/what-is-KVM)
with [libvirt](https://libvirt.org/) for local virtualization.
Performance is good and works for me.
Setup VMs is a timely task, so I am using [Vagrant](https://www.vagrantup.com/) for creating and managing VMs.

To install and use this repository, you can use `./start.sh kvm` from
[dotfiles](https://github.com/1995parham/dotfiles).

## Up and Running

You can start your Linux virtual machine first by customizing the `usvm/config.json`,
and then you can start:

```bash
cd usvm || return

vagrant up
```
