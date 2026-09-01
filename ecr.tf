resource "aws_ecr_repository" "ollama_repository" {
  name                 = "ollama-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

