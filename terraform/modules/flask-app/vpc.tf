locals {
  region = var.region
  name   = "pollinate"
}

resource "aws_eip" "nat" {
  vpc = true

  count = length(var.private_subnets_cidrs)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.availability_zones
  public_subnets  = var.public_subnets_cidrs
  private_subnets = var.private_subnets_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw          = true
  enable_nat_gateway  = true
  reuse_nat_ips       = true
  single_nat_gateway  = false
  external_nat_ip_ids = aws_eip.nat.*.id

  manage_default_network_acl   = true
  public_dedicated_network_acl = true
  default_network_acl_name     = "${local.name}-default-nacl"
  default_security_group_name  = "${local.name}-default-vpc-sg"
}