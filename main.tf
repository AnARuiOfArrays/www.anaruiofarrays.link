provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "bucket_web" {
  bucket = "test.www.anaruiofarrays.link"
  #policy = file("web_bucket_policy.json")
  
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_web_ownership" {
  bucket = aws_s3_bucket.bucket_web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

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


resource "aws_s3_bucket" "bucket_web_redirect" {
  bucket = "test.anaruiofarrays.link"
  #policy = file("web_bucket_policy.json")

  website {
    redirect_all_requests_to = aws_s3_bucket.bucket_web.id
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_web_redirect_ownership" {
  bucket = aws_s3_bucket.bucket_web_redirect.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
