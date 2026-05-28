# 1. Create the Private ECR Registry
resource "aws_ecr_repository" "gsd_repo" {
  name                 = "gsd-container-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true 
  }
}

# 2. Add a Lifecycle Policy to keep only the 3 most recent images
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.gsd_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 3 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
