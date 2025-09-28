output "alb_primary_dns"   { value = aws_lb.a.dns_name }
output "alb_secondary_dns" { value = aws_lb.b.dns_name }
output "db_primary"        { value = aws_db_instance.primary.address }
output "db_replica"        { value = aws_db_instance.replica.address }
output "s3_primary"        { value = aws_s3_bucket.a.bucket }
output "s3_secondary"      { value = aws_s3_bucket.b.bucket }
output "vpc_primary_id"    { value = aws_vpc.a.id }
output "vpc_secondary_id"  { value = aws_vpc.b.id }