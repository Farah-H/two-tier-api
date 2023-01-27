resource "aws_lb" "app" {
  name               = "${local.name}-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = module.vpc.public_subnets
  idle_timeout       = 30

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "ecs_tg" {
  name     = "${local.name}-ecs-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path     = "/"
    protocol = "HTTP"

    # one per AZ
    healthy_threshold   = 3
    unhealthy_threshold = 3

    timeout  = 2
    interval = 5
    matcher  = "200"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    type             = "forward"
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix = "${local.name}-app-lc"

  image_id             = data.aws_ami.latest_ecs_ami.image_id
  security_groups      = [aws_security_group.ecs_sg.id]
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${local.name}-ecs-cluster >> /etc/ecs/ecs.config"
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "${local.name}-ecs-asg"
  vpc_zone_identifier  = module.vpc.private_subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity = length(var.private_subnets_cidrs)
  min_size         = var.min_size
  max_size         = var.max_size
}

resource "aws_autoscaling_policy" "ecs_scale_up" {
  name                   = "${local.name}-scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_appautoscaling_target" "ecs_service_scaling_target" {
  max_capacity = var.max_size
  min_capacity = var.min_size

  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.service.name}"
  role_arn           = aws_iam_role.autoscaling_role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_service_cpu_scale_out_policy" {
  name        = "${local.name}-cpu-target-tracking-scaling-policy"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs_service_memory_scale_out_policy" {
  name        = "${local.name}-memory-target-tracking-scaling-policy"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}