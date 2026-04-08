output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet id"
  value       = aws_subnet.public.id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = [aws_subnet.public.id, aws_subnet.public_az2.id]
}

output "private_subnet_id" {
  description = "Private subnet id"
  value       = aws_subnet.private.id
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value       = [aws_subnet.private.id, aws_subnet.private_az2.id]
}
