# Vault credential store for services needing credentials
resource "boundary_credential_store_vault" "this" {
  count         = local.services_needing_creds ? 1 : 0
  name          = "Credential Store for ${var.hostname_prefix}"
  scope_id      = data.boundary_scope.project.id
  address       = var.vault_address
  token         = var.credential_store_token
  namespace     = var.vault_namespace != "" ? var.vault_namespace : null
  worker_filter = "\"vmware\" in \"/tags/platform\""
}

# Conditional creation of Vault credential library for TCP services
resource "boundary_credential_library_vault" "tcp" {
  for_each = {
    for host in var.hosts : host.hostname => host
    if var.services[0].type == "tcp" && var.services[0].use_vault_creds
  }

  name                = "${var.hostname_prefix}-${each.value.hostname}-vault-cred-library"
  description         = "Vault Credential Library for ${each.value.hostname}"

  # Check if a new credential store is created or use an existing one
  credential_store_id = length(boundary_credential_store_vault.this) > 0 ? boundary_credential_store_vault.this[0].id : var.existing_infrastructure.vault_credential_store_id

  path                = var.services[0].credential_path
  http_method         = "GET"  # Depending on Vault API, this can be customized if needed
}


# Conditional creation of Vault SSH certificate credential library
resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  for_each = {
    for host in var.hosts : host.hostname => host
    if var.services[0].type == "ssh" && var.services[0].use_vault_creds
  }

  name                = "${var.hostname_prefix}-${each.value.hostname}-ssh-cert-library"
  description         = "SSH Certificate Credential Library for ${each.value.hostname}"
  credential_store_id = length(boundary_credential_store_vault.this) > 0 ? boundary_credential_store_vault.this[0].id : var.existing_infrastructure.vault_credential_store_id
  path                = var.services[0].credential_path
  username            = "ubuntu"  # You can make this dynamic based on the input if necessary
  key_type            = "ed25519" # Default key type, can be customized per service

  extensions = {
    permit-pty = "" # Default extensions, can be customized
  }
}
