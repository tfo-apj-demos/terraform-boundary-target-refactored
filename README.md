# Boundary Target Terraform Module

This Terraform module is designed for demo purposes to create Boundary targets, credential stores, and credential libraries using HashiCorp Vault. The module is flexible and allows you to easily set up SSH or TCP-based targets that can be accessed securely through Boundary, with credentials either pre-existing or dynamically generated from Vault.

## Features
- Create SSH or TCP Boundary targets.
- Automatically generate credentials using Vault.
- Support for pre-existing credential libraries or dynamic creation.
- Simplified configuration using a minimal set of inputs.
- Target alias creation based on FQDN for easy access.

## Requirements

- Terraform >= 0.12
- Boundary provider
- Vault provider
- Access to a Vault instance and a Boundary instance.

## Usage

### Basic Example: TCP Target with Pre-Existing Credentials

```hcl
module "tcp_target_with_existing_creds" {
  source  = "github.com/tfo-apj-demos/terraform-boundary-target-refactored"

  project_name           = "shared_services"
  hostname_prefix        = "On-Prem VMware vCenter Admin"
  
  hosts = [{
    fqdn = "vcsa-98975.fe9dbbb3.asia-southeast1.gve.goog"
  }]

  services = [{
    type               = "tcp"
    port               = 443
    use_existing_creds = true
    use_vault_creds    = false
  }]

  existing_infrastructure = {
    vault_credential_store_id = "csvlt_1234ABCD",
    tcp_credential_libraries = {
      "vcsa" = "clvsclt_56TGKSD9"
    }
  }
}
```

### Example: SSH Target with Dynamically Generated Credentials

```hcl
module "ssh_target_with_vault_creds" {
  source  = "github.com/tfo-apj-demos/terraform-boundary-target-refactored"

  project_name           = "linux_admin"
  hostname_prefix        = "Linux Admin Access"
  credential_store_token = vault_token.this.client_token
  vault_address          = "https://vault.example.com:8200"

  hosts = [{
    fqdn = "linux-admin-01.example.com"
  }]

  services = [{
    type               = "ssh"
    port               = 22
    use_existing_creds = false
    use_vault_creds    = true
    credential_path    = "ssh/sign/admin-role"
  }]
}
```

### Example: TCP Target with LDAP Credentials from Vault

```hcl
module "tcp_target_with_ldap_creds" {
  source  = "github.com/tfo-apj-demos/terraform-boundary-target-refactored"

  project_name           = "shared_services"
  hostname_prefix        = "Windows RDP Access"
  credential_store_token = vault_token.this.client_token
  vault_address          = "https://vault.example.com:8200"

  hosts = [{
    fqdn = "rds-01.example.com"
  }]

  services = [{
    type               = "tcp"
    port               = 3389
    use_existing_creds = false
    use_vault_creds    = true
    credential_path    = "ldap/creds/rdp-role"
  }]
}
```

### Example: FQDN Alias for a TCP Target Without Credentials

```hcl
module "tcp_target_without_creds" {
  source  = "github.com/tfo-apj-demos/terraform-boundary-target-refactored"

  project_name    = "shared_services"
  hostname_prefix = "On-Prem NSX Admin"

  hosts = [{
    fqdn = "nsx-98984.example.com"
  }]

  services = [{
    type               = "tcp"
    port               = 443
    use_existing_creds = false
    use_vault_creds    = false
  }]
}
```

