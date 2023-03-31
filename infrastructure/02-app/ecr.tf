locals {
  ecr_repo_names = [
    "cruddur-python",
    "backend-flask"
  ]
}

resource "aws_ecr_repository" "repo" {
  for_each             = toset(local.ecr_repo_names)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
}
