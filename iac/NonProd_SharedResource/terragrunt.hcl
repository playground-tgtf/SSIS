locals {
    env_vars = yamldecode(file("${find_in_parent_folders("environment.yaml")}"))
}

generate "terraform" {
    path = "versions.tf"
    if_exists = "overwrite"
    contents = <<EOF
      terraform {
        required_version = "1.9.4"
        required_providers {
            aws = {
                 source = "hashicorp/aws"
                 version = "5.67.0"
            }
        }
       }
       EOF
}

generate "providers" {
     path = "providers.tf"
     if_exists = "overwrite"
     contents = <<EOF
    provider "aws" {
        region = var.aws_region
       }
    EOF
    }
    
  remote_state {
    backend = "s3"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
    config = {
        bucket = lower("${local.env_vars[get_env("APP_ENV_NAME")]["aws_account_name"]}-tfstate)
        key = "${local.env_vars[get_env("APP_ENV_NAME")]["app_name"]}/${get_env("APP_ENV_NAME")}/${path_relative_to_include()}/terraform.tfstate"
        region = local.env_vars[get_env("APP_ENV_NAME")]["aws_region"]
        encrypt = true
        dynamodb_table = "terraform-locks"
    }
  }

 

