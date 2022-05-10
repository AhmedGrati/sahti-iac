resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "ECSLoadBalancer" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    var.default_subnet_a_id,
    var.default_subnet_b_id,
    var.default_subnet_c_id
  ]
  # Referencing the security group
  security_groups = [aws_security_group.load_balancer_security_group.id]
}
resource "aws_alb_target_group" "target_group" {
  name        = "target-group"
  port        = 4000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.default_vpc_id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
  depends_on = [
    aws_alb.application_load_balancer
  ]
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.target_group.arn # Referencing our tagrte group
  }
}