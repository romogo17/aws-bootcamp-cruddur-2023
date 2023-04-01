terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.55.0"
    }
  }
  required_version = "~> 1.3.0"

  backend "s3" {}
}

provider "aws" {
  shared_config_files      = [var.aws_shared_config_file]
  shared_credentials_files = [var.aws_shared_credentials_file]
  profile                  = var.aws_profile
}

variable "aws_shared_config_file" {
  type        = string
  description = "AWS config file path"
}

variable "aws_shared_credentials_file" {
  type        = string
  description = "AWS shared credentials file path"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile name"
}
