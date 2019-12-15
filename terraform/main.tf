
provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
}

terraform {
  backend "s3" {}
  required_version = "~> 0.12.18"
}


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region  =  data.aws_region.current.name
  common_tags = {
    owner = "pravallika"
    email = "pravs2017@gmail.com"
    costcentre = "naresh"
    project = "streaming-app"
    live = var.live
    environment = var.env
    technical_contact = "pravallika"
  }
}
resource "aws_s3_bucket" "source" {
  bucket = "streaming-app-${local.common_tags.environment}-src"
  acl    = "private"
  tags = local.common_tags
}
resource "aws_s3_bucket" "tgt" {
  bucket = "streaming-app-${local.common_tags.environment}-tgt"
  acl    = "private"
  tags = local.common_tags
}

resource "aws_s3_bucket" "raw" {
  bucket = "streaming-app-${local.common_tags.environment}-raw"
  acl    = "private"
  tags = local.common_tags
}

resource "aws_s3_bucket" "scripts" {
  bucket = "streaming-app-${local.common_tags.environment}-scripts"
  acl    = "private"
  tags = local.common_tags
}

data "archive_file" "raw" {
  type        = "zip"
  source_file = "../../../lambda/src/main.py"
  output_path = "/tmp/raw/lambda.zip"
}

module "raw_phase" {
  source                 = "./modules/sqs_lambda_sns"
  name                   = "raw"
  s3_script_key          = "${local.common_tags.environment}/raw/main.py"
  lambda_handler         = "main.handler"
  zip_file_path          = data.archive_file.raw.output_path
  zip_file_hash          = data.archive_file.raw.output_base64sha256
  deployment_bucket_name = aws_s3_bucket.scripts.bucket
  bucket_name            = aws_s3_bucket.raw.bucket
  region                 = local.region
  tags                   = local.common_tags
}
