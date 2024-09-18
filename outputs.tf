# Output for TCP with credentials target IDs
output "tcp_with_creds_target_ids" {
  value = { for key, target in boundary_target.tcp_with_creds : key => target.id }
}

# Output for SSH with credentials target IDs
output "ssh_with_creds_target_ids" {
  value = { for key, target in boundary_target.ssh_with_creds : key => target.id }
}


# Debug output to check alias destination ID logic
output "alias_destination_ids" {
  value = {
    for host_key, host in boundary_host_static.this : host_key => {
      destination_id = contains(keys(boundary_target.tcp_with_creds), host_key) ? boundary_target.tcp_with_creds[host_key].id : contains(keys(boundary_target.ssh_with_creds), host_key) ? boundary_target.ssh_with_creds[host_key].id : null
    }
  }
}

output "alias_debug_each_key" {
  value = { for host in boundary_host_static.this : host.name => {
    tcp_id = lookup(boundary_target.tcp_with_creds, host.name, null),
    ssh_id = lookup(boundary_target.ssh_with_creds, host.name, null)
  }}
}
