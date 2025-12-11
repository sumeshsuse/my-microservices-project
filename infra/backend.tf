terraform {
  backend "s3" {
    bucket         = "my-microservices-tf-state-sumesh"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
