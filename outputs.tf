output "alb_dns_name" {
  description = "Public DNS name of the load balancer — open this in a browser"
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "instance_ids" {
  value = aws_instance.app[*].id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app.bucket
}
