provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "bucket_web" {
  bucket = "test.www.anaruiofarrays.link"
  policy = file("web_bucket_policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.bucket_web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
