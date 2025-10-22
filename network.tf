resource "libvirt_network" "vm_network" {
  name      = var.network_name
  mode      = "nat"
  domain    = var.network_domain
  addresses = [var.network_cidr]
  autostart = true
}
