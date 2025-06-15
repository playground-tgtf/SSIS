
terraform {
   source = "git::https://github.com/playground-tgtf/modules.git//s3?ref=v1.1.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  env_vars = yamldecode(file("${find_in_parent_folders("environment.yaml")}"))
}

inputs = {
  create_bucket                         = true
  bucket                                = lower("${basename(get_terragrunt_dir())}")
  attach_deny_insecure_transport_policy = true
  attach_allow_iam_roles_policy         = true
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
    Name             = lower("${basename(get_terragrunt_dir())}")
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
}

