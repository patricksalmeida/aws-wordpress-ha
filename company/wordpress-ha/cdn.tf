locals {
  s3_origin_id  = "bucket"
  alb_origin_id = "alb"
}

resource "aws_cloudfront_cache_policy" "wp_cdn_default_cache_policy" {
  name        = "${var.name}-default-cache-policy"
  default_ttl = 60
  max_ttl     = 60
  min_ttl     = 60

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Host",
          "CloudFront-Forwarded-Proto",
          "CloudFront-Is-Tablet-Viewer",
          "CloudFront-Is-Mobile-Viewer",
          "CloudFront-Is-Desktop-Viewer",
        ]
      }
    }

    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = [
          "comment_*",
          "wordpress_*",
          "wp-settings-*",
        ]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_cache_policy" "wp_cdn_admin_cache_policy" {
  name        = "${var.name}-admin-cache-policy"
  default_ttl = 60
  max_ttl     = 60
  min_ttl     = 60

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Access-Control-Request-Headers",
          "Access-Control-Request-Method",
          "CloudFront-Viewer-Metro-Code",
          "CloudFront-Viewer-Longitude",
          "CloudFront-Viewer-Latitude",
          "CloudFront-Viewer-Time-Zone",
          "CloudFront-Viewer-Postal-Code",
          "CloudFront-Viewer-City",
          "CloudFront-Viewer-Country-Region-Name",
          "CloudFront-Viewer-Country-Region",
          "CloudFront-Viewer-Country-Name",
          "CloudFront-Viewer-Country",
          "CloudFront-Viewer-Http-Version",
          "CloudFront-Forwarded-Proto",
          "CloudFront-Is-Android-Viewer",
          "CloudFront-Is-IOS-Viewer",
          "CloudFront-Is-Desktop-Viewer",
          "CloudFront-Is-SmartTV-Viewer",
          "CloudFront-Is-Tablet-Viewer",
          "CloudFront-Is-Mobile-Viewer",
          "Referer",
          "Origin",
          "Authorization",
          "Host",
          "Accept-Encoding",
          "Accept-Language",
          "Accept-Datetime",
          "Accept-Charset",
          "Accept"
        ]
      }
    }

    cookies_config {
      cookie_behavior = "all"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_cache_policy" "wp_cdn_static_cache_policy" {
  name        = "${var.name}-static-cache-policy"
  default_ttl = 60
  max_ttl     = 60
  min_ttl     = 60

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "wp_bucket_origin_access_control" {
  name                              = "${var.name}-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "wp_cdn" {
  origin {
    origin_id   = local.alb_origin_id
    domain_name = aws_route53_record.wp_alb_alias.fqdn
  }

  origin {
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket.wp_static.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.wp_bucket_origin_access_control.id
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = [var.host]

  default_cache_behavior {
    target_origin_id       = local.alb_origin_id
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = aws_cloudfront_cache_policy.wp_cdn_default_cache_policy.id
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  ordered_cache_behavior {
    target_origin_id       = local.alb_origin_id
    path_pattern           = "wp-admin/*"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.wp_cdn_admin_cache_policy.id
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 10
    compress               = true
  }

  ordered_cache_behavior {
    target_origin_id       = local.alb_origin_id
    path_pattern           = "wp-login.php"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.wp_cdn_admin_cache_policy.id
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 10
    compress               = true
  }

  ordered_cache_behavior {
    target_origin_id       = local.s3_origin_id
    path_pattern           = "wp-content/*"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id        = aws_cloudfront_cache_policy.wp_cdn_static_cache_policy.id
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.name}-${var.environment}-cdn"
    Environment = "${var.environment}"
  }
}
