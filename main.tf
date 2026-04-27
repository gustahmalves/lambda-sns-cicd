terraform {
  required_version = ">=1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.0.0"
    }

  }

  backend "s3" {
    bucket = "terraform-lambda-cicd"
    key    = "terraform.tfstate"
    region = "us-east-1"

  }
}

module "sns" {
  source = "./modules/sns"

}

module "lambda" {
  source              = "./modules/lambda"
  sns_cicd_lambda_arn = module.sns.sns_cicd_lambda_arn
}

