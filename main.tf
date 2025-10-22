# Create storage pool
resource "libvirt_pool" "vm_pool" {
  name = var.pool_name
  type = "dir"

  target {
    path = "/var/lib/libvirt/images"
  }
}

# Create default network
resource "libvirt_network" "vm_network" {
  name      = var.network_name
  mode      = "nat"
  domain    = "1995parham.usvm"
  addresses = ["192.168.122.0/24"]
  autostart = true
}

# Download cloud images
resource "libvirt_volume" "base_images" {
  depends_on = [libvirt_pool.vm_pool]

  for_each = { for k, v in var.vms : k => v.image_url }

  name   = "${each.key}-base.qcow2"
  pool   = var.pool_name
  source = each.value
  format = "qcow2"
}

# Create VM root volumes from base images
resource "libvirt_volume" "vm_disks" {
  for_each = var.vms

  name           = "${each.key}-root.qcow2"
  pool           = var.pool_name
  base_volume_id = libvirt_volume.base_images[each.key].id
  size           = each.value.disk_size * 1024 * 1024 * 1024 # Convert GB to bytes
  format         = "qcow2"
}

# Cloud-init configuration
resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"
  pool = var.pool_name
  user_data = each.value.user_data != "" ? each.value.user_data : templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    hostname            = "${each.key}-${var.hostname_suffix}"
    ssh_authorized_keys = concat(var.ssh_authorized_keys, each.value.ssh_keys)
    enable_ansible      = each.value.enable_ansible
  })
}

# Define VMs
resource "libvirt_domain" "vms" {
  for_each = var.vms

  name      = each.key
  memory    = each.value.memory
  vcpu      = each.value.cpus
  autostart = each.value.autostart

  cloudinit = libvirt_cloudinit_disk.vm_init[each.key].id

  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }

  network_interface {
    network_id     = libvirt_network.vm_network.id
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  # Ensure cloud-init completes before marking as complete
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ${each.key} to be ready..."
      timeout 300 bash -c 'until nc -z ${self.network_interface[0].addresses[0]} 22 2>/dev/null; do sleep 2; done' || true
    EOT
  }
}
