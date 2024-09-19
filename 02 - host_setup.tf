# Data Sources to get the organizational and project scopes
data "boundary_scope" "org" {
  scope_id = "global"
  name     = "tfo_apj_demos"
}

data "boundary_scope" "project" {
  scope_id = data.boundary_scope.org.id
  name     = var.project_name
}

# Host catalog for static hosts (created if not provided)
resource "boundary_host_catalog_static" "this" {
  name        = "Host Catalog for ${var.hostname_prefix}"
  description = "Host Catalog ${var.hostname_prefix}"
  scope_id    = data.boundary_scope.project.id
}

# Define static hosts, mapped by hostname
resource "boundary_host_static" "this" {
  for_each        = { for host in var.hosts : host.fqdn => host }
  type            = "static"
  name            = each.value.fqdn
  host_catalog_id = boundary_host_catalog_static.this.id
  address         = each.value.fqdn
}

# Host set for static hosts, mapping them to the catalog
resource "boundary_host_set_static" "this" {
  type            = "static"
  name            = "${var.hostname_prefix}-servers"
  host_catalog_id = boundary_host_catalog_static.this.id
  host_ids        = [for host in boundary_host_static.this : host.id]
}