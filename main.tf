## Establish the latest version IDs for Fedora Core OS & k0s
data "external" "versions" {
  program = [
    "${path.module}/scripts/versions.sh",
  ]
}

locals {
  k0s_version                = data.external.versions.result["k0s_version"]
  coreos_version             = data.external.versions.result["fcos_version"]
  coreos_image_url           = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${local.coreos_version}/x86_64/fedora-coreos-${local.coreos_version}-qemu.x86_64.qcow2.xz"
  coreos_compressed_filename = basename(local.coreos_image_url)
  coreos_filename            = trimsuffix(local.coreos_compressed_filename, ".xz")
  coreos_local_path          = "/tmp/"
  coreos_compressed_file_uri = "${local.coreos_local_path}${local.coreos_compressed_filename}"
  coreos_file_uri            = "${local.coreos_local_path}${local.coreos_filename}"
  coreos_file_image_uri      = "${local.coreos_file_uri}.img"
}

# Download & decompress the latest Fedora Core OS image
resource "null_resource" "coreos_qcow2" {
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      if [ ! -f ${local.coreos_file_image_uri} ]; then \
        rm -f ${local.coreos_file_image_uri} && \
        wget ${local.coreos_image_url} -O ${local.coreos_compressed_file_uri} && \
        xz -v -d ${local.coreos_compressed_file_uri} && \
        mv ${local.coreos_file_uri} ${local.coreos_file_image_uri}; \
      fi
    EOT
  }
}

## Upload the latest Fedora CoreOS image to ProxMox ISO data storage
resource "proxmox_virtual_environment_file" "coreos_qcow2" {
  depends_on = [null_resource.coreos_qcow2]

  content_type = "iso"
  datastore_id = var.proxmox.iso_datastore_id
  node_name    = var.proxmox.host

  source_file {
    path = local.coreos_file_image_uri
  }
}

## Build Ignition files for each Fedora Core OS host and store them in the ProxMox snippits data store
module "master-ignition" {
  depends_on                   = [proxmox_virtual_environment_file.coreos_qcow2]
  source                       = "./modules/fedora_coreos_ignition_template"
  host_name                    = format("master%s", count.index)
  proxmox_snippet_datastore_id = var.proxmox.snippet_datastore_id
  proxmox_host                 = var.proxmox.host
  count                        = var.kubernetes.master.count
  ssh_public_key_path          = var.kubernetes.ssh_public_key_path
}

module "worker-ignition" {
  depends_on                   = [proxmox_virtual_environment_file.coreos_qcow2]
  source                       = "./modules/fedora_coreos_ignition_template"
  host_name                    = format("worker%s", count.index)
  proxmox_snippet_datastore_id = var.proxmox.snippet_datastore_id
  proxmox_host                 = var.proxmox.host
  count                        = var.kubernetes.worker.count
  ssh_public_key_path          = var.kubernetes.ssh_public_key_path
}

resource "null_resource" "coreos_proxmox_template" {
  depends_on = [module.master-ignition, module.worker-ignition]

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = var.proxmox.host
      user        = var.proxmox.user
      private_key = file(var.proxmox.ssh_private_key_path)
    }

    content = templatefile("${path.module}/templates/coreos_proxmox_template.tmpl", {
      vm_id                 = var.coreos_template.vm_id
      memory                = var.coreos_template.memory
      network_bridge        = var.coreos_template.network_bridge
      iso_storage_path      = var.proxmox.iso_storage_path
      coreos_image_filename = basename(local.coreos_file_image_uri)
      vm_disk_datastore_id  = var.proxmox.vm_disk_datastore_id
      additional_disk_size  = var.coreos_template.additional_disk_size
      cloud_init_user       = var.coreos_template.cloud_init_user
      ssh_public_keys       = var.coreos_template.ssh_public_keys
      template_name         = var.coreos_template.template_name
    })
    destination = "/tmp/coreos_proxmox_template.sh"
  }

  provisioner "remote-exec" {
    when = create
    connection {
      type        = "ssh"
      host        = var.proxmox.host
      user        = var.proxmox.user
      private_key = file(var.proxmox.ssh_private_key_path)
    }

    # Use the templatefile function to render the template creation bash script
    inline = [
      "chmod +x /tmp/coreos_proxmox_template.sh",
      "/tmp/coreos_proxmox_template.sh",
    ]
  }
}

resource "time_sleep" "sleep" {
  depends_on = [
    null_resource.coreos_proxmox_template
  ]
  create_duration = "30s"
}

module "master_fedora_coreos_instance" {

  depends_on = [
    time_sleep.sleep
  ]

  source                 = "./modules/fedora_coreos_instance"
  count                  = var.kubernetes.master.count
  name                   = format("master%s", count.index)
  memory                 = var.kubernetes.master.memory
  vcpus                  = var.kubernetes.master.vcpus
  sockets                = var.kubernetes.master.sockets
  autostart              = var.kubernetes.autostart
  default_network_bridge = var.proxmox.network_bridge
  template_node          = var.proxmox.template_node
  template_vm_id         = var.coreos_template.template_vm_id
  target_node            = var.kubernetes.master.target_node
  snippet_storage_path   = var.proxmox.snippet_storage_path
}

module "worker_fedora_coreos_instance" {

  depends_on = [
    time_sleep.sleep
  ]

  source                 = "./modules/fedora_coreos_instance"
  count                  = var.kubernetes.worker.count
  name                   = format("worker%s", count.index)
  memory                 = var.kubernetes.worker.memory
  vcpus                  = var.kubernetes.worker.vcpus
  sockets                = var.kubernetes.worker.sockets
  autostart              = var.kubernetes.autostart
  default_network_bridge = var.proxmox.network_bridge
  template_node          = var.proxmox.template_node
  template_vm_id         = var.coreos_template.template_vm_id
  target_node            = var.kubernetes.worker.target_node
  snippet_storage_path   = var.proxmox.snippet_storage_path
}

module "haproxy" {
  source                       = "./modules/haproxy"
  ha_proxy_user                = var.ha_proxy.user
  default_network_bridge       = var.proxmox.network_bridge
  template_node                = var.proxmox.template_node
  target_node                  = var.ha_proxy.target_node
  template_vm_id               = var.ha_proxy.template_vm_id
  proxmox_user                 = var.proxmox.user
  proxmox_password             = var.proxmox.password
  proxmox_host                 = var.proxmox.host
  public_key                   = var.proxmox.ssh_public_key_path
  proxmox_snippet_storage_path = var.proxmox.snippet_storage_path
  proxmox_snippet_datastore_id = var.proxmox.snippet_datastore_id
  proxmox_vm_disk_datastore_id = var.proxmox.vm_disk_datastore_id
  ip_address                   = var.ha_proxy.ip_address
  gateway                      = var.ha_proxy.gateway
}

resource "time_sleep" "sleep-haproxy" {
  depends_on = [
    module.haproxy.node
  ]
  create_duration = "90s"
}

resource "local_file" "haproxy_config" {

  depends_on = [
    module.master_fedora_coreos_instance.node,
    module.worker_fedora_coreos_instance.node,
    time_sleep.sleep-haproxy
  ]

  content = templatefile("${path.root}/templates/haproxy.tmpl",
    {
      node_map_masters = zipmap(
        module.master_fedora_coreos_instance.*.address, module.master_fedora_coreos_instance.*.name
      ),
      node_map_workers = zipmap(
        module.worker_fedora_coreos_instance.*.address, module.worker_fedora_coreos_instance.*.name
      )
    }
  )
  filename = "/tmp/haproxy.cfg"

  provisioner "file" {
    source      = "/tmp/haproxy.cfg"
    destination = "/etc/haproxy/haproxy.cfg"
    connection {
      type        = "ssh"
      host        = module.haproxy.proxy_ipv4_address
      user        = var.ha_proxy.user
      private_key = file(var.proxmox.ssh_private_key_path)
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = module.haproxy.proxy_ipv4_address
      user        = var.ha_proxy.user
      private_key = file(var.proxmox.ssh_private_key_path)
    }

    inline = [
      "sudo systemctl restart haproxy"
    ]
  }
}

resource "local_file" "k0sctl_config" {

  depends_on = [
    local_file.haproxy_config
  ]

  content = templatefile("${path.root}/templates/k0s.tmpl",
    {
      node_map_masters = zipmap(
        tolist(module.master_fedora_coreos_instance.*.address), tolist(module.master_fedora_coreos_instance.*.name)
      ),
      node_map_workers = zipmap(
        tolist(module.worker_fedora_coreos_instance.*.address), tolist(module.worker_fedora_coreos_instance.*.name)
      ),
      "user"        = "core",
      "k0s_version" = local.k0s_version,
      "ha_proxy_server" : module.haproxy.proxy_ipv4_address,
      "ssh_private_key_path" = var.proxmox.ssh_private_key_path
    }
  )
  filename = "k0sctl.yaml"
}

resource "null_resource" "setup_kubernetes_cluster" {

  depends_on = [
    local_file.k0sctl_config
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      MAX_RETRIES=5
      RETRY_INTERVAL=10
      for ((i = 1; i <= MAX_RETRIES; i++)); do
        k0sctl apply --config k0sctl.yaml --disable-telemetry
        code=$?
        if [ $code -eq 0 ]; then
          break
        fi
        if [ $i -lt $MAX_RETRIES ]; then
          echo "Unable to apply config. Retrying in 10 seconds..."
          sleep $RETRY_INTERVAL
        else
          echo "Maximum retries reached. Unable to apply config."
          exit 1
        fi
      done
      mkdir -p ~/.kube
      k0sctl kubeconfig > ~/.kube/config --disable-telemetry
      chmod 600 ~/.kube/config
    EOT
    when        = create
  }
}

resource "local_file" "ansible_hosts" {

  depends_on = [
    local_file.haproxy_config
  ]

  content = templatefile("${path.root}/templates/ansible.tmpl",
    {
      node_map_masters = zipmap(
        tolist(module.master_fedora_coreos_instance.*.address), tolist(module.master_fedora_coreos_instance.*.name)
      ),
      node_map_workers = zipmap(
        tolist(module.worker_fedora_coreos_instance.*.address), tolist(module.worker_fedora_coreos_instance.*.name)
      ),
      "ansible_port" = 22,
      "ansible_user" = "core"
    }
  )
  filename = "hosts"

}
