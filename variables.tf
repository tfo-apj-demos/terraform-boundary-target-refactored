variable "project_name" {
  type        = string
  description = "The Boundary project name in which to create the targets and associated resources."
}

variable "vault_address" {
  type        = string
  description = "Address of the Vault server for credential management."
  default     = ""
}

variable "vault_namespace" {
  type        = string
  description = "Namespace in Vault, if applicable."
  default     = ""
}

variable "hosts" {
  type        = list(string)
  description = "List of FQDNs for the hosts."
}

variable "port" {
  type        = number
  description = "Port number to use for all hosts (e.g., 22 for SSH, 443 for TCP)."
}

variable "credential_source" {
  type        = string
  description = "Type of credential source. Options: 'vault', 'existing'."
  default     = "existing"
}

variable "credential_store_token" {
  type        = string
  description = "Token for Vault credential store."
  default     = ""
}

variable "credential_path" {
  type        = string
  description = "Vault credential path if using Vault credentials."
  default     = ""
}

variable "target_type" {
  type        = string
  description = "Type of Boundary target. Options: 'ssh', 'tcp'."
  default     = "tcp"
}

variable "use_host_set" {
  type        = bool
  description = "If true, create a host set and use it in host_source_ids for the target. If false, use a single address per target."
  default     = true
}

variable "use_credentials" {
  type        = bool
  description = "If true, creates a credential store and library for the target. If false, no credentials are used."
  default     = true
}

variable "target_name" {
  type        = string
  description = "A unique name for the target, used to differentiate resources in the module."
}

variable "target_mode" {
  type        = string
  description = "Mode for target creation: 'single' for each host individually, 'group' for a group of hosts."
  default     = "single"
}

variable "alias_name" {
  type        = string
  description = "The name for the target alias. This can be set explicitly to control how the alias appears."
  default     = ""
}