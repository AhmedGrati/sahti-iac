output "alb_target_group_arn" {
    value = aws_alb_target_group.target_group.arn
}

output "alb_listsner_id" {
  value = aws_alb_listener.listener.id
}