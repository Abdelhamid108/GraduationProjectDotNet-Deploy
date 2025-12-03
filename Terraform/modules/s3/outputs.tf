output "app_s3_bucket_name" {
 value = aws_s3_bucket.amazona_bucket.id
}

output "s3_user_acess_key" {
 value     = aws_iam_access_key.s3_user.id
 sensitive = true
}

output "s3_user_secret_key" {
 value     = aws_iam_access_key.s3_user.secret
 sensitive = true
}
