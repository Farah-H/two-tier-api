locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_service_role_pd" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_role_pd" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ec2.amazonaws.com", "dynamodb.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "autoscaling_pd" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

# Get the latest AMI ID for the ECS optimized Amazon Linux 2 image.
# Works for any region
data "aws_ami" "latest_ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

resource "aws_iam_role" "ecs_service_role" {
  name                  = "ecs_service_role"
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ecs_service_role_pd.json
  force_detach_policies = true

  inline_policy {
    name = "ecs-service"

    policy = file("../../modules/flask-app/policies/ecs-service.json")
  }
}

resource "aws_iam_role" "ec2_role" {
  name                  = "ec2_role"
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ec2_role_pd.json
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  force_detach_policies = true

  inline_policy {
    name   = "ecs-service-cluster"
    policy = file("../../modules/flask-app/policies/ecs-service-cluster.json")
  }

  inline_policy {
    name   = "dynamo-access"
    policy = file("../../modules/flask-app/policies/dynamo-access.json")
  }

  inline_policy {
    name   = "ecr-access"
    policy = file("../../modules/flask-app/policies/ecr-access.json")
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "autoscaling_role" {
  name                  = "autoscaling_role"
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.autoscaling_pd.json
  force_detach_policies = true

  inline_policy {
    name = "service-autoscaling"

    policy = file("../../modules/flask-app/policies/service-autoscaling.json")
  }
}