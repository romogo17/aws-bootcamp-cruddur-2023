# *****************************************************************************
# * ECS Service Execution Role — Role used by fargate to setup the containers
# *****************************************************************************
resource "aws_iam_policy" "service" {
  name = "CruddurServiceExecutionPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/cruddur/backend-flask/*"
      },
    ]
  })
}

resource "aws_iam_role" "service" {
  name = "CruddurServiceExecutionRole"

  managed_policy_arns = [
    aws_iam_policy.service.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# *****************************************************************************
# * ECS Task Role — Role used by the containers
# *****************************************************************************
resource "aws_iam_policy" "ssm_access" {
  name = "SSMAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "dynamodb_crud_access" {
  name = "DynamoDBCrudAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTable",
          "dynamodb:ConditionCheckItem"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_dynamodb_table.cruddur_messages_table.arn}",
          "${aws_dynamodb_table.cruddur_messages_table.arn}/index/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "task" {
  name = "CruddurTaskRole"

  managed_policy_arns = [
    aws_iam_policy.ssm_access.arn,
    aws_iam_policy.dynamodb_crud_access.arn,
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        # Recommended to prevent the confused deputy problem
        # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          },
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}
