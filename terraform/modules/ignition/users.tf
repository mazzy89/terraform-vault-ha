locals {
  users = lookup(yamldecode(var.users), "users", [])
}

data "ignition_user" "users" {
  count = length(local.users)

  name     = lookup(local.users[count.index], "name", null)
  home_dir = "/home/${lookup(local.users[count.index], "name", null)}"
  shell    = "/bin/bash"

  groups = lookup(local.users[count.index], "groups", [])

  ssh_authorized_keys = lookup(local.users[count.index], "sshAuthorizedKeys", [])
}
