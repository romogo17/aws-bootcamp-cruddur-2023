resource "aws_xray_sampling_rule" "cruddur" {
  rule_name      = "Cruddur"
  resource_arn   = "*"
  priority       = 9000
  fixed_rate     = 0.1
  reservoir_size = 5
  service_name   = "cruddur-backend-flask"
  service_type   = "*"
  host           = "*"
  http_method    = "*"
  url_path       = "*"
  version        = 1
}

resource "aws_xray_group" "cruddur" {
  group_name        = "cruddur"
  filter_expression = "service(\"cruddur-backend-flask\")"
}
