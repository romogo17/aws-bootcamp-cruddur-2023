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

variable "db_connection_url" {
  description = "Database connection URL"
  type        = string
}

variable "rollbar_access_token" {
  description = "Rollbar access token"
  type        = string
}

variable "honeycomb_api_key" {
  description = "Honeycomb api key"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito user pool id"
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "Cognito user pool client id"
  type        = string
}

variable "ecs_service_desired_count" {
  description = "Desired count for the ECS services"
  type        = string
}

variable "cruddur_dns_name" {
  type        = string
  description = "Name of the Route53 zone"
}
