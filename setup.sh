#!/usr/bin/env bash
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${BOLD}$1${NC}"
}

check_requirements() {
    log_header "Checking requirements..."

    local missing=0

    # Check terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        echo "  Install: https://www.terraform.io/downloads"
        missing=1
    else
        log_info "Terraform $(terraform version -json | jq -r '.terraform_version') found"
    fi

    # Check libvirt
    if ! command -v virsh &> /dev/null; then
        log_error "libvirt is not installed"
        echo "  Install: sudo apt install libvirt-daemon-system libvirt-clients (Debian/Ubuntu)"
        echo "          sudo dnf install libvirt (Fedora)"
        echo "          sudo pacman -S libvirt (Arch)"
        missing=1
    else
        log_info "libvirt found"
    fi

    # Check KVM support
    if [ ! -e /dev/kvm ]; then
        log_error "/dev/kvm not found - KVM may not be supported or enabled"
        missing=1
    else
        log_info "KVM support detected"
    fi

    # Check libvirt connection
    if ! virsh -c qemu:///system list &> /dev/null; then
        log_error "Cannot connect to libvirt (qemu:///system)"
        echo "  You may need to add your user to the libvirt group:"
        echo "    sudo usermod -aG libvirt \$USER"
        echo "    newgrp libvirt"
        missing=1
    else
        log_info "libvirt connection successful"
    fi

    # Optional: check jq for better output
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed (optional, for better output)"
    fi

    if [ $missing -ne 0 ]; then
        log_error "Some requirements are missing. Please install them and try again."
        exit 1
    fi

    log_info "All requirements met!"
}

setup_ssh_key() {
    log_header "SSH Key Setup"

    local default_key="$HOME/.ssh/id_rsa.pub"

    if [ ! -f "$default_key" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
        log_warn "No SSH public key found at $default_key or $HOME/.ssh/id_ed25519.pub"
        read -p "Generate a new SSH key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
            default_key="$HOME/.ssh/id_ed25519.pub"
        else
            log_warn "Skipping SSH key setup"
            return
        fi
    else
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            default_key="$HOME/.ssh/id_ed25519.pub"
        fi
    fi

    log_info "Found SSH key: $default_key"
    export SSH_KEY="$default_key"
}

create_tfvars() {
    log_header "Creating terraform.tfvars"

    if [ -f terraform.tfvars ]; then
        log_warn "terraform.tfvars already exists"
        read -p "Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing terraform.tfvars"
            return
        fi
    fi

    cp terraform.tfvars.example terraform.tfvars

    if [ -n "${SSH_KEY:-}" ] && [ -f "$SSH_KEY" ]; then
        local key_content=$(cat "$SSH_KEY")
        # Escape special characters for sed
        local escaped_key=$(echo "$key_content" | sed 's/[\/&]/\\&/g')
        sed -i.bak "s|# \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...\",|\"$escaped_key\",|" terraform.tfvars
        rm terraform.tfvars.bak
        log_info "Added SSH key to terraform.tfvars"
    fi

    log_info "Created terraform.tfvars - review and customize as needed"
}

main() {
    log_header "KVM/Libvirt Terraform Setup"

    check_requirements
    setup_ssh_key
    create_tfvars

    log_header "Next steps:"
    echo "  1. Review and customize terraform.tfvars"
    echo "  2. Run: just init"
    echo "  3. Run: just plan"
    echo "  4. Run: just apply"
    echo ""
    echo "Common commands:"
    echo "  just         - Show all available commands"
    echo "  just status  - Show VM status"
    echo "  just ssh usvm - SSH into a VM"
    echo ""
    log_info "Setup complete!"
}

main "$@"
