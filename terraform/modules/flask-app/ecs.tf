locals {
  # needs to be uploaded to aws ECR in advance
  ecs_image_url = "500640810998.dkr.ecr.eu-west-1.amazonaws.com/pollinate:pollinate"
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = "${local.name}-flask-app"
  container_definitions = <<DEFINITION
[
  {
    "name": "${local.name}-ecs-flask",
    "cpu": 10,
    "image": "${local.ecs_image_url}",
    "essential": true,
    "memory": 300,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "ecs-logs",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "${local.name}-ecs-flask"
      }
    },
    "mountPoints": [
      {
        "containerPath": "/usr/local/apache2/htdocs",
        "sourceVolume": "my-vol"
      }
    ],
    "portMappings": [
      {
        "containerPort": 5000
      }
    ]
  }
]
DEFINITION
  volume {
    name = "my-vol"
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.name}-ecs-cluster"
}

resource "aws_ecs_service" "service" {
  name            = "${local.name}-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn

  desired_count = length(var.private_subnets_cidrs)

  iam_role = aws_iam_role.ecs_service_role.arn
  load_balancer {
    # needs to be the same as container name in task definition
    container_name   = "${local.name}-ecs-flask"
    container_port   = 5000
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }

  depends_on = [aws_lb_listener.alb_listener]
}
