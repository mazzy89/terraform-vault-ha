output "vault_filesystem" {
  value = data.ignition_filesystem.vault.rendered
}

output "vault_mount" {
  value = data.ignition_systemd_unit.vault_mount.rendered
}

output "vault_service" {
  value = data.ignition_systemd_unit.vault.rendered
}

output "vault_operator_unseal_service_list" {
  value = data.ignition_systemd_unit.vault_operator_unseal.*.rendered
}

output "vault_operator_configure_service" {
  value = data.ignition_systemd_unit.vault_operator_configure.rendered
}

output "node_exporter_service" {
  value = data.ignition_systemd_unit.node_exporter.rendered
}

output "update_ca_certificates_dropin" {
  value = data.ignition_systemd_unit.update_ca_certificates_dropin.rendered
}

output "vault_config_list" {
  value = data.ignition_file.vault_config.*.rendered
}

output "vault_cluster_config" {
  value = data.ignition_file.vault_cluster_config.rendered
}

output "vault_ca_crt" {
  value = data.ignition_file.vault_server_crt.rendered
}

output "vault_ca_key" {
  value = data.ignition_file.vault_server_key.rendered
}

output "directories_list" {
  value = [
    data.ignition_directory.vault_data.rendered,
    data.ignition_directory.vault_config.rendered,
    data.ignition_directory.vault_audit.rendered,
  ]
}

output "users_list" {
  value = data.ignition_user.users.*.rendered
}

output "vault_user" {
  value = data.ignition_user.vault.rendered
}

output "vault_group" {
  value = data.ignition_group.vault.rendered
}

output "vault_hostname_list" {
  value = data.ignition_file.hostname.*.rendered
}
