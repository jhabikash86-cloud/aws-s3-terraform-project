# 1. Create the Serverless ECS Cluster
resource "aws_ecs_cluster" "gsd_cluster" {
  name = "gsd-application-cluster"
}

# 2. Create the IAM Execution Role so Fargate can securely pull from ECR
resource "aws_iam_role" "ecs_execution_role" {
  name = "gsd-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ecr" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. Define the Blueprint for the Container (Task Definition)
resource "aws_ecs_task_definition" "gsd_task" {
  family                   = "gsd-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    
  memory                   = "512"    
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "gsd-web-app"
      image     = "${aws_ecr_repository.gsd_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# 4. Create a fresh Target Group for Fargate inside your existing ALB
resource "aws_lb_target_group" "fargate_targets" {
  name        = "tg-gsd-fargate"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id 
  target_type = "ip"            

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# 5. Launch and Manage the Containers (The ECS Service)
resource "aws_ecs_service" "gsd_fargate_service" {
  name            = "gsd-fargate-service"
  cluster         = aws_ecs_cluster.gsd_cluster.id
  task_definition = aws_ecs_task_definition.gsd_task.arn
  desired_count   = 2 
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id] 
    security_groups  = [aws_security_group.web_sg.id] 
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_targets.arn
    container_name   = "gsd-web-app"
    container_port   = 80
  }
}
