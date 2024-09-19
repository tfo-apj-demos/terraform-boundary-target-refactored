variable "hostname_prefix" {
  type        = string
  description = "A prefix to use for the Boundary host set."
}

variable "project_name" {
  type        = string
  description = "The Boundary project name in which to create the targets and associated resources."
}

variable "vault_address" {
  type    = string
  default = ""
}

variable "vault_namespace" {
  type    = string
  default = ""
}

variable "credential_store_token" {
  type    = string
  default = ""
}

variable "hosts" {
  type = list(object({
    fqdn = string
  }))
  description = "The hosts to register as Boundary targets."
}

variable "services" {
  description = "List of services (SSH, TCP, etc.) that need to be exposed via Boundary."
  type = list(object({
    type               = string  # The type of service ('ssh' or 'tcp')
    port               = number  # The port number the service listens on
    use_existing_creds = bool    # Whether to use existing credential libraries
    use_vault_creds    = bool    # Whether to create new credential libraries via Vault
    credential_path    = optional(string, null)  # The Vault credential path (only if use_vault_creds = true)
  }))

  validation {
    condition     = alltrue([for s in var.services : !(s.use_existing_creds && s.use_vault_creds)])
    error_message = "You cannot set both 'use_existing_creds' and 'use_vault_creds' to true for the same service. Choose one."
  }

  validation {
    condition     = alltrue([for s in var.services : !s.use_existing_creds || s.credential_path == null])
    error_message = "You cannot provide a credential_path when 'use_existing_creds' is true. Credential paths are only applicable for services using Vault credentials."
  }

  validation {
    condition     = alltrue([for s in var.services : s.use_vault_creds || s.credential_path == null])
    error_message = "You cannot provide a credential_path unless 'use_vault_creds' is true."
  }
}

variable "existing_infrastructure" {
  description = "Optional: Information about pre-existing Vault credential stores and SSH/TCP credential libraries."
  type = object({
    vault_credential_store_id = optional(string, null)    # Optional, if we have an existing Vault store
    ssh_credential_libraries  = optional(map(string), {}) # Optional, map of service name to credential library ID
    tcp_credential_libraries  = optional(map(string), {}) # Optional, map of service name to credential library ID
  })
  default = {}
}