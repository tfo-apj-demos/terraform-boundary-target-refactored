locals {
  # Map service names to their corresponding target IDs
  destination_ids = {
    for service in var.services : service.name => lookup(boundary_target.tcp_with_creds, service.name, null) != null 
      ? boundary_target.tcp_with_creds[service.name].id
      : lookup(boundary_target.ssh_with_creds, service.name, null) != null 
      ? boundary_target.ssh_with_creds[service.name].id 
      : null
  }
}

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

resource "boundary_alias_target" "service_alias" {
  for_each = {
    for host_key, host in boundary_host_static.this : host_key => host
  }

  name                      = "${each.value.name}_service_alias"
  description               = "Alias for ${each.value.name} access"
  scope_id                  = "global"

  # Use the address from the hosts input as the alias value
  value                     = lookup({ for host in var.hosts : host.hostname => host.address }, each.value.name, null)

  # Ensure destination_id is correctly mapped based on the service type
  destination_id            = local.destination_ids[each.key]
    
  authorize_session_host_id = each.value.id
}

