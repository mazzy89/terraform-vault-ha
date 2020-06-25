resource "local_file" "vault_key" {
  content  = tls_private_key.vault.private_key_pem
  filename = "./generated/tls/vault.key.pem"
}

resource "local_file" "vault_crt" {
  content  = tls_locally_signed_cert.vault.cert_pem
  filename = "./generated/tls/vault.crt.pem"
}
