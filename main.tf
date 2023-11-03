terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "The AWS region"
  default     = "eu-central-1"
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["./credentials"]
  profile                  = "default"
}

resource "aws_cognito_user_pool" "pool" {
  name                       = "app-pool"
  alias_attributes           = ["preferred_username", "email"]
  auto_verified_attributes   = ["email"]
  email_verification_subject = "Verify your email"
  email_verification_message = "Please click the link below to verify your email address. {####}"

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  username_configuration {
    case_sensitive = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  # Required attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false
    string_attribute_constraints {
      min_length = "5"
      max_length = "255"
    }
  }

  schema {
    name                     = "updated"
    attribute_data_type      = "DateTime"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      max_length = "100"
    }
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "my-super-unique-example-domain"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name = "app-client"

  user_pool_id    = aws_cognito_user_pool.pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.client.id
}
