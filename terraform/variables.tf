variable "default_tags" {
  description = "Default resource tags"
  type        = map(string)
  default = {
        author      = "Krzysztof Pas Konrad Sarnecki"
        application = "SQL Day 2025"
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default = ""
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default = ""
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
  default = ""
}

variable "sql_username" {
  description = "SQL Server additional username"
  type        = string
  default = ""
}

variable "firewall_rules" {
    type = list(object({
        name            = string
        start_ip_address = string
        end_ip_address   = string
    }))
    default = [
        {
            name            = "IP1"
            start_ip_address = "001.001.001.001"
            end_ip_address   = "001.001.001.001"
        },
        {
            name                = "IP2"
            start_ip_address    = "001.001.001.002"
            end_ip_address      = "001.001.001.002"
        }
    ]
}

variable "key_vault_secrets" {
  description = "Key Vault secrets"
  type        = map(string)
  default = {
    "Recreatable-Symmetric-Key-Name" = "Recreatable_Symmetric_Key"
    "Recreatable-Symmetric-Key-Source"  = "Secret_Key_Source_value"
    "Recreatable-Symmetric-Key-IV"  = "MyIdentity"
    "Recreatable-Symmetric-Key-Password"  = "StrongPassword123!"
    "Additional-Symmetric-Key-Name"  = "Additional_Symmetric_Key" 
    "Additional-Symmetric-Key-Source" = "Another_Key_Source_value"
    "Additional-Symmetric-Key-IV" = "SecondIdentity"
    "Additional-Symmetric-Key-Password" = "TopSecretPassword123!"
  }
}