# Local values for credential configuration based on inputs
locals {
  use_vault_creds = var.credential_source == "vault" && var.use_credentials
}

# Data Sources to get the organizational and project scopes
data "boundary_scope" "org" {
  scope_id = "global"
  name     = "tfo_apj_demos"
}

data "boundary_scope" "project" {
  scope_id = data.boundary_scope.org.id
  name     = var.project_name
}

# Boundary static host catalog
resource "boundary_host_catalog_static" "this" {
  count       = var.use_host_set ? 1 : 0
  name        = "Host Catalog for ${var.target_type} Targets"
  description = "Catalog for ${var.target_type} Targets"
  scope_id    = data.boundary_scope.project.id
}

resource "boundary_host_static" "this" {
  count           = var.use_host_set ? length(var.hosts) : 0
  type            = "static"
  name            = var.hosts[count.index]
  host_catalog_id = boundary_host_catalog_static.this[0].id
  address         = var.hosts[count.index]
}

resource "boundary_host_set_static" "this" {
  count           = var.use_host_set ? 1 : 0
  type            = "static"
  name            = "${var.target_type}-servers"
  host_catalog_id = boundary_host_catalog_static.this[0].id
  host_ids        = [for host in boundary_host_static.this : host.id]
}

# Conditional Vault credential store
resource "boundary_credential_store_vault" "this" {
  count         = local.use_vault_creds ? 1 : 0
  name          = "Vault Credential Store for ${var.target_type}"
  scope_id      = data.boundary_scope.project.id
  address       = var.vault_address
  token         = var.credential_store_token
  namespace     = var.vault_namespace != "" ? var.vault_namespace : null
  worker_filter = "\"vmware\" in \"/tags/platform\""
}

# Conditional TCP or SSH Vault Credential Library
resource "boundary_credential_library_vault" "tcp" {
  for_each = { for host in var.hosts : host => host if var.target_type == "tcp" && local.use_vault_creds }

  name                = "${each.key}-tcp-vault-cred-library"
  description         = "Vault TCP Credential Library for ${each.key}"
  credential_store_id = boundary_credential_store_vault.this[0].id
  path                = var.credential_path
  http_method         = "GET"
}

resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  for_each = { for host in var.hosts : host => host if var.target_type == "ssh" && local.use_vault_creds }

  name                = "${each.key}-ssh-cert-library"
  description         = "SSH Vault Credential Library for ${each.key}"
  credential_store_id = boundary_credential_store_vault.this[0].id
  path                = var.credential_path
  username            = "ubuntu"
  key_type            = "ed25519"
  extensions          = { permit-pty = "" }
}

# Boundary Target for TCP or SSH
resource "boundary_target" "this" {
  count           = length(var.hosts)
  name            = "${var.target_type}-target-${count.index}"
  type            = var.target_type
  default_port    = var.port
  scope_id        = data.boundary_scope.project.id

  # Conditionally use host set or address for target
  host_source_ids = var.use_host_set ? [boundary_host_set_static.this[0].id] : null
  address         = !var.use_host_set ? var.hosts[count.index] : null

  # Conditional injection based on credential source
  injected_application_credential_source_ids = (
    local.use_vault_creds && var.target_type == "ssh" && contains(keys(boundary_credential_library_vault_ssh_certificate.ssh), var.hosts[count.index])
  ) ? [boundary_credential_library_vault_ssh_certificate.ssh[var.hosts[count.index]].id] : null

  brokered_credential_source_ids = (
    local.use_vault_creds && var.target_type == "tcp" && contains(keys(boundary_credential_library_vault.tcp), var.hosts[count.index])
  ) ? [boundary_credential_library_vault.tcp[var.hosts[count.index]].id] : null

  ingress_worker_filter = "\"vmware\" in \"/tags/platform\""
}
