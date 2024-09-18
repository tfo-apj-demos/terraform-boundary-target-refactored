locals {
  # Generate destination_ids based on service type and hostname
  destination_ids = {
    for host in var.hosts :
    host.hostname => (
      var.services[0].type == "ssh" ? boundary_target.ssh_with_creds[host.hostname].id :
      var.services[0].type == "tcp" ? boundary_target.tcp_with_creds[host.hostname].id : null
    )
  }
}

# Boundary target for SSH services
resource "boundary_target" "ssh_with_creds" {
  for_each = { for host in var.hosts : host.hostname => host if var.services[0].type == "ssh" }

  name            = "${each.value.hostname} SSH Access"
  type            = var.services[0].type
  default_port    = var.services[0].port
  scope_id        = data.boundary_scope.project.id
  host_source_ids = [boundary_host_set_static.this.id]

  # Inject SSH credentials if provided
  injected_application_credential_source_ids = local.processed_services[each.key].use_vault_creds ? [local.ssh_credential_library_ids[each.key]] : null
}

# Boundary target for TCP services
resource "boundary_target" "tcp_with_creds" {
  for_each = { for host in var.hosts : host.hostname => host if var.services[0].type == "tcp" }

  name            = "${each.value.hostname} TCP Access"
  type            = var.services[0].type
  default_port    = var.services[0].port
  scope_id        = data.boundary_scope.project.id
  host_source_ids = [boundary_host_set_static.this.id]

  # Broker TCP credentials if provided
  brokered_credential_source_ids = local.hostname_to_service_map[each.key].use_vault_creds ? [local.tcp_credential_library_ids[each.key]] : null
}

# Boundary alias for services
resource "boundary_alias_target" "service_alias" {
  for_each = {
    for host in boundary_host_static.this : host.id => host
  }

  name                      = "${each.value.name}_service_alias"
  description               = "Alias for ${each.value.hostname} access"
  scope_id                  = "global"
  value                     = each.value.address  # Use host address directly
  destination_id            = local.destination_ids[each.key]
  authorize_session_host_id = each.value.id
}


