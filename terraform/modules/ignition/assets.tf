## This will contain Vault data
##
data "ignition_filesystem" "vault" {
  name = "vault"

  mount {
    device          = "/dev/xvdh"
    format          = "ext4"
    wipe_filesystem = true
  }
}

data "ignition_group" "vault" {
  name = "vault"
  gid  = 501
}

data "ignition_user" "vault" {
  name = "vault"

  home_dir = "/home/vault"
  shell    = "/bin/false"
  uid      = 501

  no_create_home = true
  system         = true
  no_user_group  = true

  primary_group = data.ignition_group.vault.gid
}

## This create the directory vault and data
##
data "ignition_directory" "vault_data" {
  filesystem = "vault"

  path = "//data"
  mode = 493

  uid = data.ignition_user.vault.uid
  gid = data.ignition_group.vault.gid
}

data "ignition_directory" "vault_config" {
  filesystem = "vault"

  path = "/config"
  mode = 493

  uid = data.ignition_user.vault.uid
  gid = data.ignition_group.vault.gid
}

data "ignition_directory" "vault_audit" {
  filesystem = "vault"

  path = "/audit"
  mode = 493

  uid = data.ignition_user.vault.uid
  gid = data.ignition_group.vault.gid
}

data "template_file" "vault_config_template" {
  count = var.cluster_size

  template = file("${path.module}/resources/vault/server/config.json")

  vars = {
    vault_node_id      = "vault-${var.aws_availability_zones[count.index]}-${count.index}"
    vault_storage_path = var.vault_storage_path

    # Auto Unseal KMS
    aws_region = var.aws_region
    kms_key    = var.kms_key
  }
}

data "ignition_file" "hostname" {
  count = var.cluster_size

  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420

  content {
    content = "vault-${var.aws_availability_zones[count.index]}-${count.index}"
  }
}


data "ignition_file" "vault_config" {
  count = var.cluster_size

  filesystem = "vault"
  path       = "/config/config.json"
  mode       = 420

  uid = data.ignition_user.vault.uid
  gid = data.ignition_group.vault.gid

  content {
    content = data.template_file.vault_config_template[count.index].rendered
  }
}

data "ignition_file" "vault_cluster_config" {
  filesystem = "vault"
  path       = "/config/config.yml"
  mode       = 420

  uid = data.ignition_user.vault.uid
  gid = data.ignition_group.vault.gid

  content {
    content = file("${path.module}/resources/vault/cluster/config.yml")
  }
}

data "ignition_systemd_unit" "vault_mount" {
  name    = "etc-vault.mount"
  enabled = true

  content = file("${path.module}/resources/mounts/etc-vault.mount")
}

data "ignition_systemd_unit" "vault" {
  name    = "vault.service"
  enabled = true

  content = templatefile("${path.module}/resources/services/vault.service", {
    vault_version = var.vault_version
    vault_uid     = data.ignition_user.vault.uid
  })
}

data "ignition_systemd_unit" "node_exporter" {
  name    = "node-exporter.service"
  enabled = true

  content = templatefile("${path.module}/resources/services/node-exporter.service", {
    node_exporter_version = var.node_exporter_version
  })
}

data "ignition_systemd_unit" "vault_operator_unseal" {
  count = var.cluster_size

  enabled = true
  name    = "vault-operator@unseal.service"

  content = templatefile("${path.module}/resources/services/vault-operator@unseal.service", {
    ## These are used by bank-vaults to encrypt and store
    ## recovery keys produced from the init step in Vault
    ##
    aws_region    = var.aws_region
    aws_kms       = var.kms_key
    aws_s3_bucket = var.aws_s3_bucket
    ## S3 prefix must finish with a trailing slash i.e. vault.cluster.local/
    aws_s3_prefix = var.aws_s3_prefix

    ## Internal ALB
    aws_loadbalancer_dns = var.aws_loadbalancer_dns

    vault_uid = data.ignition_user.vault.uid
  })
}

data "ignition_systemd_unit" "vault_operator_configure" {
  enabled = true
  name    = "vault-operator@configure.service"

  content = templatefile("${path.module}/resources/services/vault-operator@configure.service", {
    ## These are used by bank-vaults to encrypt and store
    ## recovery keys produced from the init step in Vault
    ##
    aws_region    = var.aws_region
    aws_kms       = var.kms_key
    aws_s3_bucket = var.aws_s3_bucket
    ## S3 prefix must finish with a trailing slash i.e. vault.cluster.local/
    aws_s3_prefix = var.aws_s3_prefix

    vault_uid         = data.ignition_user.vault.uid
    vault_mount       = "/etc/vault"
    vault_config_file = data.ignition_file.vault_cluster_config.path
  })
}
