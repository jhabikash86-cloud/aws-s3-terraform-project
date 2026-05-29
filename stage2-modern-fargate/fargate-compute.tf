# Public Application Load Balancer
resource "aws_lb" "external_alb" {
  name               = "fargate-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "fargate-alb" }
}

# Target Group pointing directly to Serverless IPs instead of VMs
resource "aws_lb_target_group" "fargate_targets" {
  name        = "fargate-container-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # 👈 CRITICAL: Targets individual container tasks via IP routing

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# ALB Listener directing web traffic to the Fargate pool
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_targets.arn
  }
}