terraform {
  backend "s3" {
    bucket         = "sumesh-tfstate-us-east-1"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
