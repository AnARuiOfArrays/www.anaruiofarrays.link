#Set provider as AWS
provider "aws" {
  region = var.region
}

#Create AWS S3 bucket for website
resource "aws_s3_bucket" "bucket_web" {
  bucket = var.subdomain_web
  policy = file("bucket_web_policy.json")
  
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

#Set ownership controls for web bucket
resource "aws_s3_bucket_ownership_controls" "bucket_web_ownership" {
  bucket = aws_s3_bucket.bucket_web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Create website html, css, and js objects in web bucket
resource "aws_s3_bucket_object" "bucket_web_html" {
  bucket = aws_s3_bucket.bucket_web.id
  key    = "index.html"
  source = "index.html"
}

resource "aws_s3_bucket_object" "bucket_web_css" {
  bucket = aws_s3_bucket.bucket_web.id
  key    = "styles.css"
  source = "styles.css"
}

resource "aws_s3_bucket_object" "bucket_web_js" {
  bucket = aws_s3_bucket.bucket_web.id
  key    = "visitor_counter.js"
  source = "visitor_counter.js"
}

#Create S3 bucket for domain
resource "aws_s3_bucket" "bucket_domain" {
  bucket  = var.domain
  #policy = file("bucket_domain_policy.json")

  website {
    redirect_all_requests_to = aws_s3_bucket.bucket_web.id
  }
}

#Set ownership controls for domain bucket
resource "aws_s3_bucket_ownership_controls" "bucket_domain_ownership" {
  bucket = aws_s3_bucket.bucket_domain.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Create CloudFront distribution for web
resource "aws_cloudfront_distribution" "bucket_web_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket_web.bucket_regional_domain_name
    origin_id   = var.subdomain_web
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

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
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

#Create CloudFront distribution for domain
resource "aws_cloudfront_distribution" "bucket_domain_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket_domain.bucket_regional_domain_name
    origin_id   = var.domain
  }

  enabled         = true
  is_ipv6_enabled = true
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
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

resource "aws_route53_record" "record_domain" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.bucket_domain_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.bucket_domain_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "record_subdomain_web" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.subdomain_web
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.bucket_web_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.bucket_web_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
