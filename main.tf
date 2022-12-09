#Set provider as AWS
provider "aws" {
  region  = var.region
}

#Create AWS S3 bucket for website
resource "aws_s3_bucket" "web" {
  bucket = var.subdomain_web
  policy = templatefile("bucket_web_policy.json", {bucket = var.subdomain_web})
  
  website {
    redirect_all_requests_to = aws_s3_bucket.domain.bucket_regional_domain_name
  }
}

#Set ownership controls for web bucket
resource "aws_s3_bucket_ownership_controls" "web" {
  bucket = aws_s3_bucket.web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Create website html, css, and js objects in web bucket
resource "aws_s3_bucket_object" "web_html" {
  bucket       = aws_s3_bucket.domain.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "web_css" {
  bucket       = aws_s3_bucket.domain.id
  key          = "styles.css"
  source       = "styles.css"
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "web_js" {
  bucket       = aws_s3_bucket.domain.id
  key          = "visitor_counter.js"
  source       = "visitor_counter.js"
  content_type = "text/javascript"
}

#Create S3 bucket for domain
resource "aws_s3_bucket" "domain" {
  bucket  = var.domain
  policy = templatefile("bucket_web_policy.json", {bucket = var.domain})

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
  
    website {
    index_document = "index.html"
    }
}

#Set ownership controls for domain bucket
resource "aws_s3_bucket_ownership_controls" "domain" {
  bucket = aws_s3_bucket.domain.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Create ACM certificate 
resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain
  subject_alternative_names = ["www.${var.domain}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

#Create hosted zone
resource "aws_route53_zone" "primary" {
  name = var.domain
}

#Create A records
resource "aws_route53_record" "a_domain" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.domain.domain_name
    zone_id                = aws_cloudfront_distribution.domain.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a_web" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.subdomain_web
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}

#Validate certificate
data "aws_route53_zone" "primary" {
  name         = var.domain
  private_zone = false
  depends_on   = [aws_route53_zone.primary]
}

#Create records
resource "aws_route53_record" "records" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.records : record.fqdn]
}
  
#Create CloudFront distribution for web
resource "aws_cloudfront_distribution" "web" {
  origin {
    domain_name = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id   = var.subdomain_web
  }

  enabled             = true
  is_ipv6_enabled     = true

  aliases = [var.subdomain_web]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.subdomain_web

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

#Create CloudFront distribution for domain
resource "aws_cloudfront_distribution" "domain" {
  origin {
    domain_name = aws_s3_bucket.domain.bucket_regional_domain_name
    origin_id   = var.domain
  }

  enabled         = true
  is_ipv6_enabled = true
  default_root_object = "index.html"
  aliases         = [var.domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.domain

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
