module "webserver" {
  source = "../../modules/webserver/"

  region               = "us-east-1"
  vpc_cidr             = "10.1.0.0/16"
  public_subnets_cidrs = ["10.1.101.0/24", "10.1.111.0/24", "10.1.121.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
