output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "vault_cluster_nodes_ips" {
  value = module.cluster.private_ips
}