variable "admin_cidr" {
  description = "Public IPv4 address allowed to use SSH and WireGuard"
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR, for example 203.0.113.10/32."
  }
}
