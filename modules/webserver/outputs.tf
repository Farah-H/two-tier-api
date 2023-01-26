output "page_url" {
  value = "http://${aws_elb.webserver.dns_name}"
}

output "nat_gateway_ip" {
  value = module.vpc.nat_public_ips[*]
}