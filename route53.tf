data "aws_route53_zone" "public" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_health_check" "a" {
  type                        = "HTTP"
  fqdn                        = aws_lb.a.dns_name
  resource_path               = "/"
  request_interval            = 30
  failure_threshold           = 3
}

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.app_record_name
  type    = "A"
  set_identifier = "primary-a"
  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.a.id
  alias {
    name                   = aws_lb.a.dns_name
    zone_id                = aws_lb.a.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.app_record_name
  type    = "A"
  set_identifier = "secondary-b"
  failover_routing_policy { type = "SECONDARY" }
  alias {
    name                   = aws_lb.b.dns_name
    zone_id                = aws_lb.b.zone_id
    evaluate_target_health = true
  }
}
