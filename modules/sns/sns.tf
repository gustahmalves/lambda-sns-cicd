resource "aws_sns_topic" "cicd_lambda" {
  name = "cicd_lambda"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cicd_lambda.arn
  protocol  = "email"
  endpoint  = var.email

}