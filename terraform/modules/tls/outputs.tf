output "vault_cert_pem" {
  value = tls_locally_signed_cert.vault.cert_pem
}

output "vault_key_pem" {
  value = tls_private_key.vault.private_key_pem
}
