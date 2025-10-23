# List available commands
default:
    @just --list

# Initialize Terraform
init:
    terraform init

# Validate Terraform configuration
validate:
    terraform validate

# Format Terraform files
fmt:
    terraform fmt -recursive

# Show what Terraform will do
plan:
    terraform plan

# Create/update VMs
apply:
    terraform apply

# Alias for apply
up: apply

# Destroy all VMs
destroy:
    terraform destroy

# Alias for destroy
down: destroy

# Show VM status
status:
    @terraform show -json 2>/dev/null | jq -r '.values.outputs.vm_info.value // {} | to_entries[] | "\(.key): \(.value.status) - IP: \(.value.ip)"' || echo "No VMs found. Run 'just apply' first."

# List all VMs
list:
    @sudo @sudo virsh list --all

# SSH into a VM (usage: just ssh usvm)
ssh VM:
    #!/usr/bin/env bash
    set -euo pipefail
    IP=$(terraform output -json vm_ips 2>/dev/null | jq -r '.{{ VM }} // empty')
    if [ -z "$IP" ]; then
        echo "VM '{{ VM }}' not found"
        echo "Available VMs:"
        terraform output -json vm_ips 2>/dev/null | jq -r 'keys[]' || echo "No VMs found"
        exit 1
    fi
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP

# Show VM IP addresses
ips:
    @terraform output -json vm_ips 2>/dev/null | jq -r 'to_entries[] | "\(.key): \(.value)"' || echo "No VMs found"

# Clean Terraform state and cache
clean:
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

# Open virsh console (usage: just console usvm)
console VM:
    @sudo virsh console {{ VM }}

# Start a stopped VM (usage: just start usvm)
start VM:
    @sudo virsh start {{ VM }}

# Stop a running VM (usage: just stop usvm)
stop VM:
    @sudo virsh shutdown {{ VM }}

# Restart a VM (usage: just restart usvm)
restart VM:
    @sudo virsh reboot {{ VM }}

# Create a snapshot (usage: just snapshot usvm snap1)
snapshot VM NAME:
    @sudo virsh snapshot-create-as {{ VM }} {{ NAME }}

# List snapshots (usage: just snapshot-list usvm)
snapshot-list VM:
    @sudo virsh snapshot-list {{ VM }}

# Restore a snapshot (usage: just snapshot-restore usvm snap1)
snapshot-restore VM NAME:
    @sudo virsh snapshot-revert {{ VM }} {{ NAME }}

# Delete a snapshot (usage: just snapshot-delete usvm snap1)
snapshot-delete VM NAME:
    @sudo virsh snapshot-delete {{ VM }} {{ NAME }}

# Show detailed VM info (usage: just info usvm)
info VM:
    @sudo virsh dominfo {{ VM }}

# Force stop a VM (usage: just force-stop usvm)
force-stop VM:
    @sudo virsh destroy {{ VM }}

# Auto-start VM on host boot (usage: just autostart usvm)
autostart VM:
    @sudo virsh autostart {{ VM }}

# Disable auto-start (usage: just no-autostart usvm)
no-autostart VM:
    @sudo virsh autostart --disable {{ VM }}

# Show VM console output (usage: just logs usvm)
logs VM:
    @sudo virsh console {{ VM }} --force

# Run Ansible playbook on a VM (usage: just ansible usvm playbook.yml)
ansible VM PLAYBOOK:
    #!/usr/bin/env bash
    set -euo pipefail
    IP=$(terraform output -json vm_ips 2>/dev/null | jq -r '.{{ VM }} // empty')
    if [ -z "$IP" ]; then
        echo "VM '{{ VM }}' not found"
        exit 1
    fi
    ansible-playbook -i "${IP}," {{ PLAYBOOK }}

# Nuclear option: destroy ALL VMs, networks, and volumes using virsh (no Terraform state needed)
nuke:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "⚠️  WARNING: This will destroy ALL VMs, networks, and volumes!"
    echo "This operation cannot be undone."
    read -p "Are you sure? (type 'yes' to confirm): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi

    echo ""
    echo "🔥 Starting cleanup..."
    echo ""

    # Destroy and undefine all running VMs
    echo "Stopping all VMs..."
    for vm in $(sudo virsh list --name); do
        if [ -n "$vm" ]; then
            echo "  - Destroying VM: $vm"
            sudo virsh destroy "$vm" 2>/dev/null || true
        fi
    done

    # Undefine all VMs (including stopped ones)
    echo ""
    echo "Removing all VM definitions..."
    for vm in $(sudo virsh list --all --name); do
        if [ -n "$vm" ]; then
            echo "  - Undefining VM: $vm"
            sudo virsh undefine "$vm" --remove-all-storage --nvram 2>/dev/null || \
            sudo virsh undefine "$vm" --remove-all-storage 2>/dev/null || \
            sudo virsh undefine "$vm" 2>/dev/null || true
        fi
    done

    # Destroy and undefine all networks (except default)
    echo ""
    echo "Removing all networks (except 'default')..."
    for net in $(sudo virsh net-list --all --name); do
        if [ -n "$net" ] && [ "$net" != "default" ]; then
            echo "  - Destroying network: $net"
            sudo virsh net-destroy "$net" 2>/dev/null || true
            sudo virsh net-undefine "$net" 2>/dev/null || true
        fi
    done

    # Remove all volumes from all pools
    echo ""
    echo "Removing all volumes..."
    for pool in $(sudo virsh pool-list --all --name); do
        if [ -n "$pool" ]; then
            echo "  - Checking pool: $pool"
            sudo virsh pool-refresh "$pool" 2>/dev/null || true
            for vol in $(sudo virsh vol-list "$pool" --name 2>/dev/null); do
                if [ -n "$vol" ]; then
                    echo "    - Deleting volume: $vol"
                    sudo virsh vol-delete --pool "$pool" "$vol" 2>/dev/null || true
                fi
            done
        fi
    done

    # Clean Terraform state and cache
    echo ""
    echo "Cleaning Terraform state and cache..."
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

    echo ""
    echo "✅ Cleanup complete! You can now run 'just init && just apply' to start fresh."
