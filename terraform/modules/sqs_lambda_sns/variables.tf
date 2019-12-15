variable "tags" {
  description = "Common tags"
}

variable "name" {
  description = "The name of the lambda, SQS and topic"
  type        = string
}

variable "s3_script_key" {
  description = "The file name of the lambda code packages as ZIP"
  type        = string
}

variable "zip_file_path" {
  type = string
}

variable "zip_file_hash" {
  type = string
}


variable "bucket_name" {
  description = "S3 bucket to be accessed by lambda"
  type        = string
  default     = ""
}

variable "bucket_prefix" {
  description = "S3 prefix to write raw lambda"
  type        = string
  default     = "raw"
}

variable "source_topic_arn" {
  default = ""
  type    = string
}

variable "deployment_bucket_name" {
  description = "S3 bucket to deploy the ZIP file with the code"
  type        = string
  default     = ""
}

variable "lambda_handler" {
  description = "The name of the lambda handler (the function called by lambda)"
  type        = string
}

variable "region" {
  description = "Name of the region, i.e. eu-west-1"
}
