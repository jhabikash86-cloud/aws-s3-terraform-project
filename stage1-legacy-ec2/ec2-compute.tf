# Public Application Load Balancer
resource "aws_lb" "external_alb" {
  name               = "legacy-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "legacy-alb" }
}

# Target Group pointing to EC2 Instances
resource "aws_lb_target_group" "web_tg" {
  name        = "legacy-ec2-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

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

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Legacy EC2 Instance 1 (Private Subnet 1)
resource "aws_instance" "web_server_1" {
  ami                    = "ami-060e277c0d4cce553" # Amazon Linux 2 AMI for ap-southeast-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Legacy EC2 Web Server 1</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "legacy-web-server-1" }
}

# Legacy EC2 Instance 2 (Private Subnet 2)
resource "aws_instance" "web_server_2" {
  ami                    = "ami-060e277c0d4cce553"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Legacy EC2 Web Server 2</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "legacy-web-server-2" }
}

# Attach Instance 1 to Target Group
resource "aws_lb_target_group_attachment" "web_server_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

# Attach Instance 2 to Target Group
resource "aws_lb_target_group_attachment" "web_server_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}