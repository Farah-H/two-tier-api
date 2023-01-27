module "flask-app" {
  source = "../../modules/flask-app/"

  region                = "eu-west-1"
  vpc_cidr              = "10.0.0.0/16"
  public_subnets_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  availability_zones    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
