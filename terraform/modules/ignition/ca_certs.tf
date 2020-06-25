data "ignition_systemd_unit" "update_ca_certificates_dropin" {
  name    = "update-ca-certificates.service"
  enabled = true

  dropin {
    name    = "10-always-update-ca-certificates.conf"
    content = file("${path.module}/resources/dropins/10-always-update-ca-certificates.conf")
  }
}

data "ignition_file" "vault_server_crt" {
  path = "/etc/ssl/vault/vault.crt.pem"

  mode       = 256
  uid        = data.ignition_user.vault.uid
  gid        = data.ignition_group.vault.gid
  filesystem = "root"

  content {
    content = var.vault_server_crt_pem
  }
}

data "ignition_file" "vault_server_key" {
  path = "/etc/ssl/vault/vault.key.pem"

  mode       = 256
  uid        = data.ignition_user.vault.uid
  gid        = data.ignition_group.vault.gid
  filesystem = "root"

  content {
    content = var.vault_server_key_pem
  }
}
