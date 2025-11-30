output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 Node.js instance"
  value       = aws_instance.nodejs_instance.public_ip
}

output "ec2_instance_private_ip" {
  description = "Private IP address of the EC2 Node.js instance"
  value       = aws_instance.nodejs_instance.private_ip
}

output "ec2_instance_id" {
  description = "ID of the EC2 Node.js instance"
  value       = aws_instance.nodejs_instance.id
}

output "rds_endpoint" {
  description = "Endpoint address of the MySQL RDS instance"
  value       = aws_db_instance.mysql_rds.endpoint
}

output "rds_port" {
  description = "Port of the MySQL RDS instance"
  value       = aws_db_instance.mysql_rds.port
}

output "rds_instance_id" {
  description = "ID of the MySQL RDS instance"
  value       = aws_db_instance.mysql_rds.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_1a_id" {
  description = "ID of the public subnet in ap-south-1a"
  value       = aws_subnet.public_subnet_1a.id
}

output "public_subnet_1b_id" {
  description = "ID of the public subnet in ap-south-1b"
  value       = aws_subnet.public_subnet_1b.id
}
