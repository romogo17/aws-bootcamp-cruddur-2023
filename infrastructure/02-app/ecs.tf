# *****************************************************************************
# * AWS SSM Secure Strings
# *****************************************************************************
locals {
  secret_names = {
    CONNECTION_URL                  = var.db_connection_url
    ROLLBAR_ACCESS_TOKEN            = var.rollbar_access_token
    OTEL_EXPORTER_OTLP_HEADERS      = "x-honeycomb-team=${var.honeycomb_api_key}"
    AWS_COGNITO_USER_POOL_ID        = var.cognito_user_pool_id
    AWS_COGNITO_USER_POOL_CLIENT_ID = var.cognito_user_pool_client_id
  }
}

resource "aws_ssm_parameter" "secret" {
  for_each = local.secret_names
  name     = "/cruddur/backend-flask/${each.key}"
  type     = "SecureString"
  value    = each.value
}

# *****************************************************************************
# * ECS Networking
# *****************************************************************************
resource "aws_security_group" "alb_sg" {
  name        = "cruddur-alb-sg"
  description = "Security group for Cruddur LBs"
  vpc_id      = data.aws_vpc.default.id

  # TODO: remove - backend calls should go through envoy
  ingress {
    description = "cruddur-backend-flask"
    from_port   = 4567
    to_port     = 4567
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "cruddur-backend-envoy"
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cruddur_ecs_sg" {
  name        = "cruddur-ecs-sg"
  description = "Security group for Cruddur services on ECS"
  vpc_id      = data.aws_vpc.default.id

  # TODO: this should only allow the ports needed
  ingress {
    description     = "cruddur-alb"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "cruddur_backend_lb" {
  name                       = "cruddur-backend-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = data.aws_subnets.default.ids
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "cruddur_backend_tg" {
  name        = "cruddur-backend-tg"
  port        = 4567
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path     = "/api/health-check"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "cruddur_backend_listener" {
  load_balancer_arn = aws_lb.cruddur_backend_lb.arn
  port              = 4567
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur_backend_tg.arn
  }
}

# *****************************************************************************
# * ECS Cluster and Services
# *****************************************************************************
resource "aws_service_discovery_http_namespace" "cruddur" {
  name = "cruddur"
}

resource "aws_ecs_cluster" "cruddur" {
  name = "cruddur"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.cruddur.arn
  }
}

resource "aws_ecs_service" "backend_flask" {
  name                   = "backend-flask"
  cluster                = aws_ecs_cluster.cruddur.id
  task_definition        = aws_ecs_task_definition.backend_flask.arn
  desired_count          = 1
  enable_execute_command = true
  launch_type            = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.cruddur_ecs_sg.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.cruddur.arn
    service {
      client_alias {
        port = 4567
      }
      discovery_name = "backend-flask"
      port_name      = "backend-flask"
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cruddur_backend_tg.arn
    container_name   = "backend-flask"
    container_port   = 4567
  }
}


# *****************************************************************************
# * ECS Task Definitions
# *****************************************************************************
resource "aws_ecs_task_definition" "backend_flask" {
  family                   = "backend-flask"
  execution_role_arn       = aws_iam_role.service.arn
  task_role_arn            = aws_iam_role.task.arn
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "backend-flask"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/backend-flask"
      essential = true
      healthCheck = {
        command = [
          "CMD-SHELL",
          "python /backend-flask/bin/flask/health-check"
        ],
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      },
      portMappings = [{
        name          = "backend-flask"
        containerPort = 4567
        protocol      = "tcp"
        appProtocol   = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cruddur.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "backend-flask"
        }
      }
      environment = [
        { name = "OTEL_SERVICE_NAME", value = "cruddur-backend-flask" },
        { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = "https://api.honeycomb.io" },
        { name = "FRONTEND_URL", value = "*" },
        { name = "BACKEND_URL", value = "*" },
        { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.name }
      ]
      secrets = [
        { name = "CONNECTION_URL", valueFrom = aws_ssm_parameter.secret["CONNECTION_URL"].arn },
        { name = "ROLLBAR_ACCESS_TOKEN", valueFrom = aws_ssm_parameter.secret["ROLLBAR_ACCESS_TOKEN"].arn },
        { name = "OTEL_EXPORTER_OTLP_HEADERS", valueFrom = aws_ssm_parameter.secret["OTEL_EXPORTER_OTLP_HEADERS"].arn },
        { name = "AWS_COGNITO_USER_POOL_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_ID"].arn },
        { name = "AWS_COGNITO_USER_POOL_CLIENT_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_CLIENT_ID"].arn },
      ]
    },
    # {
    #   name      = "second"
    #   image     = "service-second"
    #   cpu       = 10
    #   memory    = 256
    #   essential = true
    #   portMappings = [
    #     {
    #       containerPort = 443
    #       hostPort      = 443
    #     }
    #   ]
    # }
  ])
}


