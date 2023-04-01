locals {
  ecr_repo_names = [
    "cruddur-python",
    "backend-flask",
    "frontend-react-js",
    "envoy",
    "authz",
    "otel-collector"
  ]
}

resource "aws_ecr_repository" "repo" {
  for_each             = toset(local.ecr_repo_names)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
}
