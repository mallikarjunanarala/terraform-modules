# ------------------------------------------------------------------- #
# AWS Elastic File System (EFS) environment with encryption and backup
# enforced per security guardrails (resolves CKV_AWS_184, CKV_AWS_42,
# CKV_AWS_15, CKV2_AWS_64, CKV_AWS_7, CKV_AWS_33, CKV_AWS_227).
# AUTHOR: ADAM M | +91-9739110917 | www.wezvatech.in
# ------------------------------------------------------------------- #

provider "aws" {
  region = "ap-south-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to resolve current AWS account ID for use in KMS key policy
data "aws_caller_identity" "current" {}

# Customer-managed KMS key for EFS encryption
resource "aws_kms_key" "efs_cmk" {
  description             = "CMK for wezvatech-sandbox-efs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Explicit key policy (resolves CKV2_AWS_64)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "wezvatech-sandbox-efs-cmk"
    Environment = "Dev"
  }
}

# ✅ Fixed: EFS File System with encryption enabled and CMK assigned (resolves CKV_AWS_184)
resource "aws_efs_file_system" "demo_efs" {
  creation_token = "wezvatech-aiops-demo"
  encrypted      = true
  kms_key_id     = aws_kms_key.efs_cmk.arn

  tags = {
    Name        = "wezvatech-sandbox-efs"
    Environment = "Dev"
  }
}

# ✅ Fixed: Backup policy enabled (resolves CKV_AWS_15)
resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.demo_efs.id

  backup_policy {
    status = "ENABLED"
  }
}

