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
