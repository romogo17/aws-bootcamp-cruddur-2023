# *****************************************************************************
# * ACM
# *****************************************************************************
resource "aws_acm_certificate" "cruddur" {
  domain_name               = var.cruddur_dns_name
  subject_alternative_names = ["*.${var.cruddur_dns_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cruddur" {
  for_each = {
    for dvo in aws_acm_certificate.cruddur.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.cruddur_route53_zone.zone_id
}

resource "aws_acm_certificate_validation" "cruddur" {
  certificate_arn         = aws_acm_certificate.cruddur.arn
  validation_record_fqdns = [for record in aws_route53_record.cruddur : record.fqdn]
}

# *****************************************************************************
# * DNS records
# *****************************************************************************
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.cruddur_route53_zone.zone_id
  name    = var.cruddur_dns_name
  type    = "A"

  alias {
    name                   = aws_lb.cruddur_backend_lb.dns_name
    zone_id                = aws_lb.cruddur_backend_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.cruddur_route53_zone.zone_id
  name    = "api.${var.cruddur_dns_name}"
  type    = "A"

  alias {
    name                   = aws_lb.cruddur_backend_lb.dns_name
    zone_id                = aws_lb.cruddur_backend_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "otel_collector" {
  zone_id = data.aws_route53_zone.cruddur_route53_zone.zone_id
  name    = "otel-collector.${var.cruddur_dns_name}"
  type    = "A"

  alias {
    name                   = aws_lb.cruddur_backend_lb.dns_name
    zone_id                = aws_lb.cruddur_backend_lb.zone_id
    evaluate_target_health = true
  }
}
