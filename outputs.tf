output "credential_store_id" {
  value = boundary_credential_store_vault.this[0].id
  description = "The ID of the Vault credential store created."
}