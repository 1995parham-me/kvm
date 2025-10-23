<h1 align="center"> KVM </h1>

<p align="center">
  <img alt="logo" src="./.github/assets/logo.png" />
</p>

## Introduction

I am utilizing **[KVM](https://www.redhat.com/en/topics/virtualization/what-is-KVM) with [libvirt](https://libvirt.org/)** for local virtualization.
The performance is satisfactory and aligns with my requirements.

Setting up virtual machines (VMs) can be quite time-consuming. To streamline this process, I am using **[Terraform](https://www.terraform.io/)** with the [libvirt provider](https://github.com/dmacvicar/terraform-provider-libvirt) to declaratively manage VMs.

## Why Terraform over Vagrant?

- **Fast VM spin-up**: Uses pre-built cloud images instead of installing from scratch
- **Declarative configuration**: Infrastructure as code with state management
- **Better resource management**: Automatic cleanup and dependency tracking
- **Cloud-init support**: Automated VM provisioning without manual setup
- **Snapshot support**: Easy backup and restore via libvirt

## Prerequisites

### Required

- **Terraform** >= 1.5 - [Install](https://www.terraform.io/downloads)
- **libvirt/KVM** - Virtualization platform
  - Ubuntu/Debian: `sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients`
  - Fedora: `sudo dnf install @virtualization`
  - Arch: `sudo pacman -S libvirt qemu-base`
- **virsh** - Command-line tool for libvirt (included with libvirt)

### Optional but Recommended

- **jq** - For better output formatting
- **just** - Command runner for convenient shortcuts
  - Install: `curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin`
  - Or via package manager: https://github.com/casey/just#installation

### User Permissions

Add your user to the libvirt group:

```bash
sudo usermod -aG libvirt $USER
newgrp libvirt
```

## Quick Start

### 1. Run Setup Script

The setup script will check requirements and create your initial configuration:

```bash
./setup.sh
```

### 2. Customize Configuration

Edit `terraform.tfvars` to define your VMs:

```hcl
vms = {
  usvm = {
    memory      = 8192
    cpus        = 8
    disk_size   = 50
    image_url   = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    autostart   = false
    enable_ansible = true
    ssh_keys    = ["ssh-rsa AAAAB3Nza... your-key-here"]
  }
}

ssh_authorized_keys = ["ssh-rsa AAAAB3Nza... your-key-here"]
```

### 3. Initialize and Apply

```bash
just init    # Initialize Terraform
just plan    # Preview changes
just apply   # Create VMs
```

## Common Commands

```bash
# VM Management
just apply          # Create/update VMs
just destroy        # Destroy all VMs
just status         # Show VM status and IPs
just ips            # Show IP addresses

# SSH Access
just ssh usvm       # SSH into a VM

# VM Control (via virsh)
just start usvm     # Start a VM
just stop usvm      # Stop a VM
just restart usvm   # Restart a VM
just console usvm   # Open console

# Snapshots
just snapshot usvm backup1         # Create snapshot
just snapshot-list usvm            # List snapshots
just snapshot-restore usvm backup1 # Restore snapshot

# Utilities
just                # Show all commands
just validate       # Validate configuration
just fmt            # Format Terraform files
```

## Available Cloud Images

### Ubuntu

- **24.04 LTS** (Recommended): `https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img`
- **22.04 LTS**: `https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img`

### Debian

- **12 (Bookworm)**: `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2`

### Arch Linux

- **Latest**: `https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2`

### Fedora

- **40**: `https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2`

## Configuration Details

### VM Options

| Option           | Type   | Default | Description                |
| ---------------- | ------ | ------- | -------------------------- |
| `memory`         | number | -       | RAM in MB                  |
| `cpus`           | number | -       | Number of vCPUs            |
| `disk_size`      | number | -       | Root disk size in GB       |
| `image_url`      | string | -       | Cloud image URL            |
| `autostart`      | bool   | false   | Auto-start VM on host boot |
| `ssh_keys`       | list   | []      | VM-specific SSH keys       |
| `enable_ansible` | bool   | false   | Install Ansible in VM      |

### Cloud-Init

VMs are provisioned with cloud-init, which:

- Sets hostname
- Creates user `parham` with sudo access
- Installs essential packages (git, build-essential, etc.)
- Configures SSH access
- Updates system packages
- Sets up MOTD

Customize the template at `templates/cloud-init.yml.tftpl`

## Advanced Usage

### Custom Cloud-Init

Override default cloud-init:

```hcl
vms = {
  custom = {
    memory    = 4096
    cpus      = 4
    disk_size = 30
    image_url = "..."
    user_data = file("${path.module}/my-cloud-init.yml")
  }
}
```

### Multiple VMs

Define multiple VMs in `terraform.tfvars`:

```hcl
vms = {
  web = {
    memory = 4096
    cpus   = 4
    # ...
  }

  db = {
    memory = 8192
    cpus   = 8
    # ...
  }
}
```

### Ansible Provisioning

You can run Ansible playbooks on your VMs:

```bash
# After VM is created
just ssh usvm  # Get IP or check 'just ips'

# Run Ansible manually with just
just ansible usvm playbook.yml

# Or manually
VM_IP=$(terraform output -json vm_ips | jq -r '.usvm')
ansible-playbook -i "${VM_IP}," playbook.yml
```

## Troubleshooting

### Can't connect to libvirt

```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Start if needed
sudo systemctl start libvirtd

# Ensure user is in libvirt group
groups | grep libvirt
```

### VM fails to get IP

Check network:

```bash
virsh net-list --all
virsh net-start default  # if not active
```

### Cloud-init not working

View cloud-init logs in VM:

```bash
just console usvm
# Login and check: sudo cloud-init status --long
```

## Clean Up

```bash
just destroy  # Destroy all VMs
just clean    # Remove Terraform state/cache
```
