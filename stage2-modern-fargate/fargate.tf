# Elastic Container Service (ECS) Logical Orchestration Cluster
resource "aws_ecs_cluster" "main" {
  name = "gsd-application-cluster"
}

# IAM Role enabling Fargate to spin up and execute infrastructure tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "fargate-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach standard AWS policy for pulling container blueprints
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Structural Task Definition Blueprint detailing resources
resource "aws_ecs_task_definition" "app" {
  family                   = "gsd-fargate-task"
  network_mode             = "awsvpc" # Required layout for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "web-app-container"
    image     = "${aws_ecr_repository.app.repository_url}:latest" # Dynamic tie to repository
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# Fargate Service coordinating replica container scaling
resource "aws_ecs_service" "gsd_fargate_service" {
  name            = "gsd-fargate-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.web_sg.id] # Fixed lineup referencing file 2
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_targets.id
    container_name   = "web-app-container"
    container_port   = 80
  }
}