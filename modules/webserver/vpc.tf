locals {
  region    = var.region
  name      = "pollinate"
  prod_only = var.env == "prod" ? 1 : 0
}

resource "aws_eip" "nat" {
  vpc = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.availability_zones
  public_subnets  = var.public_subnets_cidrs
  private_subnets = var.private_subnets_cidrs

  create_igw          = true
  enable_nat_gateway  = true
  reuse_nat_ips       = true
  single_nat_gateway  = true
  external_nat_ip_ids = aws_eip.nat.*.id

  manage_default_network_acl   = true
  public_dedicated_network_acl = true
  default_network_acl_name     = "${local.name}-default-nacl"
  default_security_group_name  = "${local.name}-default-sg"
}