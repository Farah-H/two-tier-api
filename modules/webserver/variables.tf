// Required Variables

variable "region" {
  type = string
}

variable "availability_zones" {
  description = "Allowing this to be set using variables because some regions have more"
  type        = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets_cidrs" {
  description = "Should be the same length or < len[availability_zones]"
  type        = list(string)
}

variable "private_subnets_cidrs" {
  description = "Should be the same length or < len[availability_zones]"
  type        = list(string)
}
// Optional Variables

variable "min_size" {
  type    = number
  default = 3
}

variable "max_size" {
  type    = number
  default = 9
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "env" {
  type    = string
  default = "prod"
}
