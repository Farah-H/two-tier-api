locals {
  private_key = file(pathexpand("~/.ssh/${local.name}.pem"))
}

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_elb" "webserver" {
  name                      = "${local.name}-elb"
  security_groups           = [aws_security_group.webserver.id]
  subnets                   = module.vpc.public_subnets
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
}

resource "aws_launch_configuration" "webserver" {
  name_prefix                 = "${local.name}-webserver-lc"
  image_id                    = data.aws_ami.latest-ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  enable_monitoring           = true
  security_groups             = [aws_security_group.webserver.id]
  user_data                   = file("../../app/provision.sh")
  key_name                    = local.name


  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(pathexpand("~/.ssh/${local.name}.pem"))
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' webserver.yml"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webserver" {
  name_prefix          = "${local.name}-webserver-asg"
  launch_configuration = aws_launch_configuration.webserver.name
  vpc_zone_identifier  = module.vpc.public_subnets

  max_size = var.max_size
  min_size = var.min_size

  default_instance_warmup   = 60
  health_check_grace_period = 60

  load_balancers        = [aws_elb.webserver.id]
  max_instance_lifetime = 604800 # 7 days 
}

