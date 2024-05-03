resource "aws_route53_zone" "wp_domain_zone" {
  name = var.host
  
  tags = {
    Name        = "${var.name}-${var.environment}-dns"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "wp_main_alias" {
  zone_id = aws_route53_zone.wp_domain_zone.zone_id
  name    = var.host
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.wp_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.wp_cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wp_www_alias" {
  zone_id = aws_route53_zone.wp_domain_zone.zone_id
  name    = "www.${var.host}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.wp_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.wp_cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wp_alb_alias" {
  zone_id = aws_route53_zone.wp_domain_zone.zone_id
  name    = "alb.${var.host}"
  type    = "A"

  alias {
    name                   = aws_lb.wp_alb.dns_name
    zone_id                = aws_lb.wp_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wp_certificate_records" {
  for_each = {
    for dvo in aws_acm_certificate.wp_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.wp_domain_zone.zone_id
}
