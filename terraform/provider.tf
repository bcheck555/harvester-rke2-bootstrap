# Terraform provider

# Harvester
provider "harvester" {
  kubeconfig = "../kubeconfig"
}
provider "kubernetes" {
  config_path = "../kubeconfig"
}