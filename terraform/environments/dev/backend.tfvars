bucket = "terraform-state-dev-streaming-app"

key = "dev/terraform.tfstate"

session_name = "terraform"

dynamodb_table = "terraform-dev-state-lock"

region = "eu-west-1"

encrypt = true