provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "bucket_web" {
  bucket = "test.www.anaruiofarrays.link"
  acl    = "public-read"
  policy = file("web_bucket_policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}


resource "aws_s3_bucket_website_configuration" "bucket_web_config" {
  bucket = aws_s3_bucket.bucket_primary.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors_config" {
  bucket = aws_s3_bucket.bucket_primary.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}
