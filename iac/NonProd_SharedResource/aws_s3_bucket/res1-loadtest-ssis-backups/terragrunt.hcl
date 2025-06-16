
terraform {
   source = "git::https://github.com/playground-tgtf/modules.git//s3?ref=v1.2.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  env_vars = yamldecode(file("${find_in_parent_folders("environment.yaml")}"))
  bucket_name = lower(basename(get_terragrunt_dir()))

  app_env     = get_env("APP_ENV_NAME")
  prod_envs   = ["DR", "Prod", "ProdSharedResource"]

  is_prod_like = contains(local.prod_envs, local.app_env)

  noncurrent_days = local.is_prod_like ? 65 : 19
  retention       = local.is_prod_like ? 2  : 1
}

inputs = {
  create_bucket                         = true
  bucket                                = local.bucket_name
  attach_deny_insecure_transport_policy = false
  attach_allow_iam_roles_policy         = false
  is_directory_bucket = false
  versioning = {
    status     = true
    mfa_delete = false
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  bucket_additional_tags = {
    Name             = local.bucket_name
    ApplicationOwner = "kuntal.basak@resolutionlife.com.au"
    AppSupportGroup  = "RLSA_Life_Integration_Support"
    AppApproverGroup = "RLSA_Reslife_Integration_Approver"
    Criticality      = "2"
  }
  mandatory_tags = {
    Application        = "SSIS"
    CostCenter         = "50107"
    Function           = "File_Services"
    Environment        = get_env("APP_ENV_NAME")
    DataClassification = "Confidential"
  }

object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = local.retention
      }
    }
  }


 lifecycle_rule = [
    {
      id      = "default_lifecycle"
      enabled = true

      filter = {
        prefix = ""
      }

      transition = [
        {
          days          = 60
          storage_class = "INTELLIGENT_TIERING"
        },
        {
          days          = 365
          storage_class = "GLACIER_IR"
        },
        {
          days          = 1095
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      noncurrent_version_expiration = {
        days = local.noncurrent_days
      }
    }
  ]
} 