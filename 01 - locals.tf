locals {
  # Automatically generate alias based on the hostname of the machine
  generated_aliases = {
    for host in var.hosts : host.hostname => "${host.hostname}.hashicorp.local"
  }

  # Check if any service needs credentials
  services_needing_creds = length(flatten([for service in var.services : service.use_existing_creds || service.use_vault_creds ? [service] : []])) > 0

  # Process services to ensure that only one credential source is used
  processed_services = [
    for service in var.services : {
      name              = service.name
      type              = service.type
      port              = service.port
      credential_source = service.use_existing_creds ? "existing" : (service.use_vault_creds ? "vault" : null)
      # Provide default path for SSH, but require user-specified path for others if using vault creds
      credential_path = service.type == "ssh" && service.use_vault_creds ? coalesce(service.credential_path, "ssh/sign/boundary") : (service.use_vault_creds ? coalesce(service.credential_path, error("For ${service.name}, you must provide a credential path")) : null)
    }
  ]

  # Map of TCP credential library IDs, merging existing or newly created
  tcp_credential_library_ids = merge(
    lookup(var.existing_infrastructure, "tcp_credential_libraries", {}),
    { for service in local.processed_services : service.name => boundary_credential_library_vault.tcp[service.name].id
    if service.type == "tcp" && service.use_vault_creds }
  )

  # Map of SSH credential library IDs, merging existing or newly created
  ssh_credential_library_ids = merge(
    lookup(var.existing_infrastructure, "ssh_credential_libraries", {}),
    { for service in local.processed_services : service.name => boundary_credential_library_vault_ssh_certificate.ssh[service.name].id
    if service.type == "ssh" && service.use_vault_creds }
  )
}
