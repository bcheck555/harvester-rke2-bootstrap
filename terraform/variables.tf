variable "main_cluster_prefix" {
    type = string
    default = "rke2-control"
    description = "The prefix for control plane nodes"
}

variable "worker_prefix" {
    type = string
    default = "rke2-worker"
    description = "The prefix for worker nodes"
}

variable "kubeconfig_filename" {
    type = string
    default = "kube_config_server.yaml"
    description = "The name of the file to store locally containing the cluster kubeconfig"
}

variable "master_vip" {
    type = string
    default = "192.168.20.25"
    description = "The Virtual IP (VIP) attached to the control plane nodes"
}

variable "control_plane_ha_mode" {
  type = bool
  default = true
  description = "The flag for create 1 Control Plane node or 3 nodes using HA"
}

variable "worker_count" {
  type = string
  default = 3
  description = "The amount of worker nodes to create"
}

variable "node_disk_size" {
  type = string
  default = "20Gi"
  description = "The disk size of each node"
}

variable "control_plane_cpu_count" {
  type = string
  default = 2
  description = "The CPU count per control plane node"
}

variable "control_plane_memory_size" {
  type = string
  default = "4Gi"
  description = "The memory used per control plane node in XGi format"
}

variable "worker_cpu_count" {
  type = string
  default = 4
  description = "The CPU count per worker node"
}

variable "worker_memory_size" {
  type = string
  default = "8Gi"
  description = "The memory used per worker node in XGi format"
}

variable "harvester_rke2_image_name" {
  type        = string
  default = "rhel-8.9-x86_64-kvm.qcow2"
  description = "The name of the VM image to use as a base for the nodes"
}

variable "target_network_name" {
  type        = string
  default = "vlan20"
  description = "The target network name for the cluster"
}

variable "ssh_user" {
    type        = string
    default = "admin"
}

#variable "cp_network_data" {
#  type        = list
#  default = "vlan20"
#  description = "Network Data field for cloud-init"
#}
