output "proxy_ipv4_address" {
  value = proxmox_virtual_environment_vm.haproxy.ipv4_addresses[1][0]
}