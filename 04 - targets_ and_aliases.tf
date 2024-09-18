# Boundary target for SSH services needing credentials
resource "boundary_target" "ssh_with_creds" {
  for_each = { for service in var.services : service.name => service if service.type == "ssh" }

  name            = "${var.hostname_prefix} SSH Access"
  type            = each.value.type
  default_port    = each.value.port
  scope_id        = data.boundary_scope.project.id
  host_source_ids = [boundary_host_set_static.this.id]

  # Inject SSH credentials if provided
  injected_application_credential_source_ids = contains(keys(local.ssh_credential_library_ids), each.key) ? [local.ssh_credential_library_ids[each.key]] : null
  # ingress_worker_filter removed as it is not expected here
}

# Boundary target for TCP services with credentials
resource "boundary_target" "tcp_with_creds" {
  for_each = { for service in var.services : service.name => service if service.type == "tcp" }

  name            = "${var.hostname_prefix} TCP Access"
  type            = each.value.type
  default_port    = each.value.port
  scope_id        = data.boundary_scope.project.id
  host_source_ids = [boundary_host_set_static.this.id]

  # Broker TCP credentials if provided
  brokered_credential_source_ids = contains(keys(local.tcp_credential_library_ids), each.key) ? [local.tcp_credential_library_ids[each.key]] : null
  ingress_worker_filter          = "\"vmware\" in \"/tags/platform\"" # Filter for workers with the "vmware" tag
}

# Boundary alias for TCP services without credentials
resource "boundary_alias_target" "tcp_without_creds_alias" {
  for_each = {
    for host in boundary_host_static.this : host.hostname => host
    if length([for service in local.processed_services : service if service.type == "tcp" && !service.use_vault_creds]) > 0
  }

  name                      = "${each.value.name}_tcp_without_creds_alias"
  description               = "Alias for ${each.value.name} TCP access without credentials"
  scope_id                  = "global"

  # Use the address from the hosts input as the alias value
  value                     = lookup({ for host in var.hosts : host.hostname => host.address }, each.value.name, null)

  destination_id            = boundary_target.tcp_without_creds[each.value.name].id
  authorize_session_host_id = each.value.id
}

# Boundary alias for TCP services with credentials
resource "boundary_alias_target" "tcp_with_creds_alias" {
  for_each = {
    for host in boundary_host_static.this : host.hostname => host
    if length([for service in local.processed_services : service if service.type == "tcp" && service.use_vault_creds]) > 0
  }

  name                      = "${each.value.name}_tcp_with_creds_alias"
  description               = "Alias for ${each.value.name} TCP access with credentials"
  scope_id                  = "global"

  # Use the address from the hosts input as the alias value
  value                     = lookup({ for host in var.hosts : host.hostname => host.address }, each.value.name, null)

  destination_id            = boundary_target.tcp_with_creds[each.value.name].id
  authorize_session_host_id = each.value.id
}

