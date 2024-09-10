# Butane config
data "template_file" "config" {
  template = file("${path.module}/templates/config.bu.tmpl")
  vars = {
    host_name        = var.host_name
    ssh_authorized_key = file("~/.ssh/${basename(var.ssh_public_key_path)}")
  }
}

# Worker config converted to Ignition
data "ct_config" "ignition" {

  depends_on = [
    data.template_file.config
  ]

  content = data.template_file.config.*.rendered[0]
  strict  = true
}

resource "proxmox_virtual_environment_file" "proxmox_configs" {
  depends_on = [data.ct_config.ignition]

  content_type = "snippets"
  datastore_id = var.proxmox_snippet_datastore_id
  node_name    = var.proxmox_host
  overwrite    = true

  source_raw {
    data      = data.ct_config.ignition.*.rendered[0]
    file_name = "ignition_${var.host_name}.ign"
  }
}
