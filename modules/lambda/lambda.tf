data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "C:\\estudos\\terraform\\cicd-lambda\\lambdafunc.py"
  output_path = "C:\\estudos\\terraform\\cicd-lambda\\lambdafunc.zip"
}

resource "aws_lambda_function" "notifier" {
  function_name = "s3-notifier"
  runtime       = "python3.12"
  handler       = "lambdafunc.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_cicd_lambda_arn
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::lambda-sns-terraform"
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = "lambda-sns-terraform"

  lambda_function {
    lambda_function_arn = aws_lambda_function.notifier.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}