output "alb_dns_name" {
  description = "The Application Load Balancer DNS name"
  value       = aws_lb.app.*.dns_name[0]
}