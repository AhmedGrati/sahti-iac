resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "/aws/ecs/cluster"
  retention_in_days = 14
}