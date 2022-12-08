
variable "role_name_prefix" {
  type        = string
  description = "Role name prefix"
  default     = ""
}


variable "account_type" {
  type        = string
  description = "The type of the AWS account to be onboarded to Prisma Cloud (standard|organization|org_member)"
  default     = "standard"
  validation {
    condition     = can(regex("^(standard|organization|org_member)$", var.account_type))
    error_message = "Invalid input, options: \"standard\", \"organization\", \"org_member\""
  }
}

variable "protection_mode" {
  type        = string
  description = "Prisma Cloud Protection mode. (MONITOR|MONITOR_AND_PROTECT)"
  default     = "MONITOR"
  validation {
    condition     = can(regex("^(MONITOR|MONITOR_AND_PROTECT)$", var.protection_mode))
    error_message = "Invalid input, options: \"MONITOR\", \"MONITOR_AND_PROTECT\""
  }
}

variable "external_id" {
  type        = string
  description = "ExternalID for the IAM role"
  validation {
    condition     = can(regex("^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$", var.external_id))
    error_message = "ExternalID must be a valid UUID"
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}