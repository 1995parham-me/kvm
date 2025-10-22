resource "libvirt_pool" "vm_pool" {
  name = var.pool_name
  type = "dir"

  target {
    path = "/var/lib/libvirt/images"
  }
}

resource "libvirt_volume" "base_images" {
  depends_on = [libvirt_pool.vm_pool]

  for_each = { for k, v in var.vms : k => v.image_url }

  name   = "${each.key}-base.qcow2"
  pool   = var.pool_name
  source = each.value
  format = "qcow2"
}

resource "libvirt_volume" "vm_disks" {
  for_each = var.vms

  name           = "${each.key}-root.qcow2"
  pool           = var.pool_name
  base_volume_id = libvirt_volume.base_images[each.key].id
  size           = each.value.disk_size * 1024 * 1024 * 1024
  format         = "qcow2"
}
