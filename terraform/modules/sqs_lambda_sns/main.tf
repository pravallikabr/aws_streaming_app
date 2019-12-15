resource "aws_sqs_queue" "queue" {
  name                       = "${var.tags.project}_${var.tags.environment}_${var.name}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "MyQueuePolicy",
  "Statement": [
    {
      "Sid": "MySQSPolicy001",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:${var.region}::${var.tags.project}_${var.tags.environment}_${var.name}"
    }
  ]
}
EOF

  tags = merge(
    {
      "Name"        = "${var.tags.project}_${var.tags.environment}_${var.name}",
      "Description" = "SQS for ${var.name}"
    },
    var.tags
  )
}

resource "aws_sns_topic" "sns" {
  name = "${var.tags.project}_${var.tags.environment}_${var.name}"

  tags = merge(
    {
      "Name"        = "${var.tags.project}_${var.tags.environment}_${var.name}",
      "Description" = "SNS topic for ${var.name}"
    },
    var.tags
  )
}

resource "aws_sns_topic_subscription" "subscription" {
  count     = var.source_topic_arn != "" ? 1 : 0
  topic_arn = var.source_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.queue.arn
  enabled          = true
  function_name    = aws_lambda_function.raw_lambda_function.arn
  batch_size       = 10
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.tags.project}_${var.tags.environment}_${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role" {
  policy_arn = aws_iam_policy.lambda_role.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "lambda_role" {
  policy = data.aws_iam_policy_document.lambda_role.json
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = [aws_sqs_queue.queue.arn]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowSNSPermissions"
    effect    = "Allow"
    resources = [aws_sns_topic.sns.arn]

    actions = [
      "SNS:Publish",
    ]
  }

  statement {
    sid       = "AllowS3Permissions"
    effect    = "Allow"
    resources = ["arn:aws:s3:::*"]

    actions = [
      "S3:*",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["${aws_lambda_function.raw_lambda_function.arn}"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }

  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
  }
}

resource "aws_s3_bucket_object" "lambda_script_key" {
  bucket     = var.deployment_bucket_name
  key        = var.s3_script_key
  source     = var.zip_file_path
  tags       = var.tags

  etag = filemd5("${var.zip_file_path}")
}

resource "aws_lambda_function" "raw_lambda_function" {
  s3_bucket     = var.deployment_bucket_name
  s3_key        = var.s3_script_key
  function_name = "${var.tags.project}_${var.tags.environment}_${var.name}"
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler

  source_code_hash = var.zip_file_hash
  runtime          = "python3.6"
  memory_size      = "128"
  timeout          = "300"

  environment {
    variables = {
      topic_arn     = aws_sns_topic.sns.arn
      bucket_name   = "${var.bucket_name}"
      bucket_prefix = "${var.bucket_prefix}"
      environment   = "${var.tags.environment}"
      region        =  var.region
      app_name      = "${var.tags.project}_${var.tags.environment}_${var.name}"
    }
  }

  tags = merge(
    {
      "Name"        = "${var.tags.project}_${var.tags.environment}_${var.name}",
      "Description" = "Lambda for ${var.name}"
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "raw_lambda_function" {
  name              = "/aws/lambda/${var.tags.project}_${var.tags.environment}_${var.name}"
  retention_in_days = 14

  tags = merge(
    {
      "Name"        = "${var.tags.project}_${var.tags.environment}_${var.name}",
      "Description" = "Lambda for ${var.name}"
    },
    var.tags
  )
}
