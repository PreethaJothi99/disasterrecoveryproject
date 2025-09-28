resource "random_id" "s3sfx" { byte_length = 3 }

resource "aws_s3_bucket" "a" { bucket = "${var.project_name}-a-${random_id.s3sfx.hex}" }
resource "aws_s3_bucket" "b" {
  provider = aws.dr
  bucket   = "${var.project_name}-b-${random_id.s3sfx.hex}"
}

resource "aws_s3_bucket_versioning" "a" {
  bucket = aws_s3_bucket.a.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "b" {
  provider = aws.dr
  bucket   = aws_s3_bucket.b.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-crr-role"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[{Effect="Allow",Principal={Service="s3.amazonaws.com"},Action="sts:AssumeRole"}]
  })
}
resource "aws_iam_role_policy" "replication" {
  role = aws_iam_role.replication.id
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[
      {Effect="Allow",Action=["s3:GetReplicationConfiguration","s3:ListBucket"],Resource=[aws_s3_bucket.a.arn]},
      {Effect="Allow",Action=["s3:GetObjectVersion","s3:GetObjectVersionAcl","s3:GetObjectVersionTagging"],Resource=["${aws_s3_bucket.a.arn}/*"]},
      {Effect="Allow",Action=["s3:ReplicateObject","s3:ReplicateDelete","s3:ReplicateTags","s3:ObjectOwnerOverrideToBucketOwner"],Resource=["${aws_s3_bucket.b.arn}/*"]}
    ]
  })
}
resource "aws_s3_bucket_replication_configuration" "crr" {
  depends_on = [aws_iam_role_policy.replication, aws_s3_bucket_versioning.a, aws_s3_bucket_versioning.b]
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.a.id
  rule {
    id     = "replicate"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.b.arn
      storage_class = "STANDARD"
    }
    filter { prefix = var.replication_prefix }
  }
}
