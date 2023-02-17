variable "account_admin_email" {
  type        = string
  description = "Email address of the AWS account administrator"
}

variable "monthly_billing_threshold" {
  type        = number
  description = "Maximum billing threshold for billing alarms"
}
