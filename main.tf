#Set provider as AWS
provider "aws" {
  region = var.region
}

#Create AWS S3 bucket for website
resource "aws_s3_bucket" "bucket_web" {
  bucket = var.bucket_web_name
  #policy = file("bucket_web_policy.json")
  
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

#Create S3 bucket for web redirect
resource "aws_s3_bucket" "bucket_web_redirect" {
  bucket = var.bucket_web_redirect_name
  #policy = file("bucket_web_redirect_policy.json")

  website {
    redirect_all_requests_to = aws_s3_bucket.bucket_web.id
  }
}

#Set ownership controls for web redirect bucket
resource "aws_s3_bucket_ownership_controls" "bucket_web_redirect_ownership" {
  bucket = aws_s3_bucket.bucket_web_redirect.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Create CloudFront distribution for web
resource "aws_cloudfront_distribution" "bucket_web_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket_web.bucket_regional_domain_name
    origin_id                = var.bucket_web_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.bucket_web_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.bucket_web_name

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
    acm_certificate_arn = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
}

#Create CloudFront distribution for redirect to web
resource "aws_cloudfront_distribution" "bucket_web_redirect_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket_web_redirect.bucket_regional_domain_name
    origin_id                = var.bucket_web_redirect_name
  }

  enabled             = true
  is_ipv6_enabled     = true

  aliases = [var.bucket_web_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.bucket_web_redirect_name

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
    acm_certificate_arn = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
}
