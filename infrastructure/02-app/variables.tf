variable "db_username" {
  description = "Master database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "gitpod_cidr_block" {
  description = "IPv4 CIDR block of Gitpod"
  type        = string
}
