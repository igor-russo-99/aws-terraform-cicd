


# resource "aws_internet_gateway" "internet_gateway" {
#  vpc_id = aws_vpc.vpc.id
#  tags = {
#    Name = "internet_gateway"
#  }
# }

# resource "aws_route_table" "route_table" {
#  vpc_id = aws_vpc.vpc.id
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.internet_gateway.id
#  }
# }

# resource "aws_route_table_association" "subnet_route" {
#  subnet_id      = aws_subnet.subnet_az1.id
#  route_table_id = aws_route_table.route_table.id
# }

# resource "aws_route_table_association" "subnet2_route" {
#  subnet_id      = aws_subnet.subnet_az2.id
#  route_table_id = aws_route_table.route_table.id
# }

# resource "aws_security_group" "security_group" {
#   name   = "ecs-security-group"
#   vpc_id = aws_vpc.vpc.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     self        = "false"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "any"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # --- ECS Node Role ---

# data "aws_iam_policy_document" "ecs_node_doc" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ecs_node_role" {
#   name_prefix        = "demo-ecs-node-role"
#   assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
# }

# resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
#   role       = aws_iam_role.ecs_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_instance_profile" "ecs_node" {
#   name_prefix = "demo-ecs-node-profile"
#   path        = "/ecs/instance/"
#   role        = aws_iam_role.ecs_node_role.name
# }

# # --- ECS Launch Template ---

# data "aws_ssm_parameter" "ecs_node_ami" {
#   name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
# }


# resource "aws_launch_template" "ecs_ec2" {
#   name_prefix            = "demo-ecs-ec2-"
#   image_id               = data.aws_ssm_parameter.ecs_node_ami.value
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.security_group.id]

#   iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
#   monitoring { enabled = true }

#   user_data = base64encode(<<-EOF
#       #!/bin/bash
#       echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config;
#     EOF
#   )
# }


# resource "aws_autoscaling_group" "ecs_asg" {
#   vpc_zone_identifier = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]
#   desired_capacity    = 2
#   max_size            = 3
#   min_size            = 1

#   launch_template {
#     id      = aws_launch_template.ecs_ec2.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "AmazonECSManaged"
#     value               = true
#     propagate_at_launch = true
#   }
# }


# resource "aws_lb" "ecs_alb" {
#   name               = "ecs-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.security_group.id]
#   subnets            = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]

#   tags = {
#     Name = "ecs-alb"
#   }
# }

# resource "aws_lb_listener" "ecs_alb_listener" {
#   load_balancer_arn = aws_lb.ecs_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ecs_tg.arn
#   }
# }

# resource "aws_lb_target_group" "ecs_tg" {
#   name        = "ecs-target-group"
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = aws_vpc.vpc.id

#   health_check {
#     path = "/"
#   }
# }



# # --- ECR ---

# resource "aws_ecr_repository" "app" {
#   name                 = "demo-app"
#   image_tag_mutability = "MUTABLE"
#   force_delete         = true

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# output "demo_app_repo_url" {
#   value = aws_ecr_repository.app.repository_url
# }










# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "my-ecs-cluster"
# }

# resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
#   name = "test1"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

#     managed_scaling {
#       maximum_scaling_step_size = 1000
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 3
#     }
#   }
# }

# resource "aws_ecs_cluster_capacity_providers" "example" {
#   cluster_name = aws_ecs_cluster.ecs_cluster.name

#   capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
#   }
# }

# resource "aws_ecs_task_definition" "ecs_task_definition" {
#   family             = "my-ecs-task"
#   network_mode       = "awsvpc"
#   execution_role_arn = "arn:aws:iam::307644482466:role/ecsTaskExecutionRole"
#   cpu                = 256
#   runtime_platform {
#     operating_system_family = "LINUX"
#     cpu_architecture        = "X86_64"
#   }
#   container_definitions = jsonencode([
#     {
#       name      = "dockergs"
#       image     = "public.ecr.aws/f9n5f1l7/dgs:latest"
#       cpu       = 256
#       memory    = 512
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ]
#     }
#   ])
# }


# resource "aws_ecs_service" "ecs_service" {
#   name            = "my-ecs-service"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.ecs_task_definition.arn
#   desired_count   = 2

#   network_configuration {
#     subnets         = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]
#     security_groups = [aws_security_group.security_group.id]
#   }

#   force_new_deployment = true
#   placement_constraints {
#     type = "distinctInstance"
#   }

#   triggers = {
#     redeployment = timestamp()
#   }

#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
#     weight            = 100
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.ecs_tg.arn
#     container_name   = "dockergs"
#     container_port   = 80
#   }

#   depends_on = [aws_autoscaling_group.ecs_asg]
# }