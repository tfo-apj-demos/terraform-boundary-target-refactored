output "credential_store_id" {
  value       = length(boundary_credential_store_vault.this) > 0 ? boundary_credential_store_vault.this[0].id : null
  description = "The ID of the Vault credential store used for the target, if created."
}
