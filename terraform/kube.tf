resource "ssh_resource" "retrieve_config" {
  depends_on = [
    module.control.controlplane_node
  ]
  host = module.control.controlplane_node.network_interface[index(module.control.controlplane_node.network_interface.*.name, "default")].ip_address
  commands = [
    "sudo sed -i 's/127.0.0.1/${var.master_vip}/' /etc/rancher/rke2/rke2.yaml"
  ]
  user        = var.ssh_user
  private_key = tls_private_key.global_key.private_key_pem
}
resource "local_file" "kube_config_server_yaml" {
  filename = var.kubeconfig_filename
  content  = ssh_resource.retrieve_config.result
}