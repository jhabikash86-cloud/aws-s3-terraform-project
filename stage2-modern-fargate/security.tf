# Security Group for Public Fargate ALB
resource "aws_security_group" "alb_sg" {
  name        = "fargate-alb-sg"
  description = "Allow inbound HTTP traffic to public ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "fargate-alb-sg" }
}

# Modern Security Group for Private Fargate Tasks
resource "aws_security_group" "web_sg" {
  name        = "fargate-task-sg"
  description = "Allow port 80 from ALB and port 443 internally for ECR endpoints"
  vpc_id      = aws_vpc.main.id

  # Rule A: Accepts traffic passed down cleanly from the ALB
  ingress {
    description     = "Allow HTTP traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Rule B: Unlocks secure internal routing loop for ECR VPC Endpoints
  ingress {
    description = "Allow internal HTTPS traffic for VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "fargate-task-sg" }
}