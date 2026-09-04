output "instance_id" {
  value = aws_instance.app.id
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "application_url" {
  value = "http://${aws_instance.app.public_ip}:8080"
}

output "grafana_url" {
  value = "http://${aws_instance.app.public_ip}:3000"
}
