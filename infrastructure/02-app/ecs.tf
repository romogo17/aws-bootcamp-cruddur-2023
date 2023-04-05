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

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
}

resource "aws_security_group" "cruddur_ecs_sg" {
  name        = "cruddur-ecs-sg"
  description = "Security group for Cruddur services on ECS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "cruddur-alb"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Use only for direct task access (for debugging purposes)
  # ingress {
  #   description = "allow-ingress-to-tasks"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

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

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.cruddur_backend_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.cruddur.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_react_js_tg.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur_backend_envoy_tg.arn
  }

  condition {
    host_header {
      values = ["api.${var.cruddur_dns_name}"]
    }
  }
}

resource "aws_lb_listener" "http_to_https" {
  load_balancer_arn = aws_lb.cruddur_backend_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "cruddur_backend_envoy_tg" {
  name        = "cruddur-backend-envoy-tg"
  port        = 8800
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path     = "/api/health-check"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "frontend_react_js_tg" {
  name        = "frontend-react-js-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path     = "/"
    protocol = "HTTP"
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
  desired_count          = var.ecs_service_desired_count
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
    service {
      client_alias {
        port = 8800
      }
      discovery_name = "envoy"
      port_name      = "envoy"
    }
  }

  # Not needed - Backend calls should go through envoy
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.cruddur_backend_tg.arn
  #   container_name   = "backend-flask"
  #   container_port   = 4567
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.cruddur_backend_envoy_tg.arn
    container_name   = "envoy"
    container_port   = 8800
  }
}

resource "aws_ecs_service" "backend_authz" {
  name                   = "backend-authz"
  cluster                = aws_ecs_cluster.cruddur.id
  task_definition        = aws_ecs_task_definition.backend_authz.arn
  desired_count          = var.ecs_service_desired_count
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
        port = 8123
      }
      discovery_name = "authz"
      port_name      = "authz"
    }
  }
}

resource "aws_ecs_service" "frontend_react_js" {
  name                   = "frontend-react-js"
  cluster                = aws_ecs_cluster.cruddur.id
  task_definition        = aws_ecs_task_definition.frontend_react_js.arn
  desired_count          = var.ecs_service_desired_count
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
        port = 8123
      }
      discovery_name = "frontend-react-js"
      port_name      = "frontend-react-js"
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_react_js_tg.arn
    container_name   = "frontend-react-js"
    container_port   = 80
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
          "python /backend-flask/bin/health-check"
        ],
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
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
        { name = "FRONTEND_URL", value = "https://${var.cruddur_dns_name}" },
        { name = "BACKEND_URL", value = "https://api.${var.cruddur_dns_name}" },
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
    {
      name      = "envoy"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/envoy:dns-family-v4"
      essential = true
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:8001/server_info | grep state | grep -q LIVE"
        ],
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      portMappings = [{
        name          = "envoy"
        containerPort = 8800
        protocol      = "tcp"
        appProtocol   = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cruddur.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "envoy"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "backend_authz" {
  family                   = "backend-authz"
  execution_role_arn       = aws_iam_role.service.arn
  task_role_arn            = aws_iam_role.task.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "authz"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/authz"
      essential = true
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:8123/health-check | grep status | grep -q ok"
        ],
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      portMappings = [{
        name          = "authz"
        containerPort = 8123
        protocol      = "tcp"
        appProtocol   = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cruddur.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "authz"
        }
      }
      secrets = [
        { name = "AWS_COGNITO_USER_POOL_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_ID"].arn },
        { name = "AWS_COGNITO_USER_POOL_CLIENT_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_CLIENT_ID"].arn },
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "frontend_react_js" {
  family                   = "frontend-react-js"
  execution_role_arn       = aws_iam_role.service.arn
  task_role_arn            = aws_iam_role.task.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "frontend-react-js"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/frontend-react-js"
      essential = true
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:80 || exit 1"
        ],
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      portMappings = [{
        name          = "frontend-react-js"
        containerPort = 80
        protocol      = "tcp"
        appProtocol   = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cruddur.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "frontend-react-js"
        }
      }
      environment = [
        { name = "REACT_APP_BACKEND_URL", value = "http://${aws_lb.cruddur_backend_lb.dns_name}:8800" },
        { name = "REACT_APP_AWS_PROJECT_REGION", value = data.aws_region.current.name },
        { name = "REACT_APP_AWS_COGNITO_REGION", value = data.aws_region.current.name }
      ]
      secrets = [
        { name = "REACT_APP_AWS_USER_POOLS_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_ID"].arn },
        { name = "REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID", valueFrom = aws_ssm_parameter.secret["AWS_COGNITO_USER_POOL_CLIENT_ID"].arn },
      ]
    }
  ])
}


