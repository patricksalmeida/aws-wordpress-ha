resource "aws_acm_certificate" "wp_certificate" {
  domain_name               = var.host
  subject_alternative_names = ["*.${var.host}"]
  validation_method         = "DNS"
  
  tags = {
    Name        = "${var.name}-${var.environment}-cert"
    Environment = "${var.environment}"
  }
}

resource "aws_acm_certificate_validation" "wp_certificate_validation" {
  certificate_arn         = aws_acm_certificate.wp_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.wp_certificate_records : record.fqdn]
}
