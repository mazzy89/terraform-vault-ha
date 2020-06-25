data "ignition_config" "nodes" {
  count = var.cluster_size

  filesystems = [var.ign_vault_filesystem]

  directories = var.ign_directories_list

  files = compact([
    var.ign_vault_ca_key,
    var.ign_vault_ca_crt,
    var.ign_vault_config_list[count.index],
    var.ign_vault_hostname_list[count.index],
    var.ign_vault_cluster_config,
  ])

  systemd = compact([
    var.ign_vault_mount,
    var.ign_vault_service,
    var.ign_vault_operator_unseal_service_list[count.index],
    var.ign_node_exporter_service,
    var.ign_update_ca_certificates_dropin,
    var.ign_vault_operator_configure_service,
  ])

  users = concat(var.ign_users_list,
    [var.ign_vault_user]
  )

  groups = [var.ign_vault_group]
}
