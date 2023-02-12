resource "aws_route53_zone" "cruddur_subdomain" {
  name = var.route53_zone_name
}

output "zone_name_servers" {
  value       = aws_route53_zone.cruddur_subdomain.name_servers
  description = "List of name servers associated with the zone"
}
