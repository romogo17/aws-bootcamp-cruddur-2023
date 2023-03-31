resource "aws_cloudwatch_log_group" "cruddur" {
  name              = "/cruddur/fargate-cluster"
  retention_in_days = 1
}
