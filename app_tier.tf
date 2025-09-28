data "aws_ami" "a" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
data "aws_ami" "b" {
  provider    = aws.dr
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  user_data_b64 = base64encode(<<-EOF
    #!/bin/bash
    dnf -y update
    dnf -y install nginx
    echo "<h1>APP TIER - \$(hostname)</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF
  )
}

# PRIMARY (A)
resource "aws_lb" "a" {
  name               = "${var.project_name}-alb-a"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.a_public : s.id]
  security_groups    = [aws_security_group.a_alb.id]
}
resource "aws_lb_target_group" "a" {
  name     = "${var.project_name}-tg-a"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.a.id
  health_check {
    path = "/"
    port = "80"
  }
}
resource "aws_lb_listener" "a_http" {
  load_balancer_arn = aws_lb.a.arn
  port     = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.a.arn
  }
}
resource "aws_launch_template" "a" {
  name_prefix   = "${var.project_name}-a-"
  image_id      = data.aws_ami.a.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  user_data     = local.user_data_b64
  network_interfaces { security_groups = [aws_security_group.a_app.id] }
}
resource "aws_autoscaling_group" "a" {
  name                = "${var.project_name}-asg-a"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [for s in aws_subnet.a_private_app : s.id]
  launch_template {
    id      = aws_launch_template.a.id
    version = "$Latest"
  }
  target_group_arns   = [aws_lb_target_group.a.arn]
}

# SECONDARY (B)
resource "aws_lb" "b" {
  provider           = aws.dr
  name               = "${var.project_name}-alb-b"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.b_public : s.id]
  security_groups    = [aws_security_group.b_alb.id]
}
resource "aws_lb_target_group" "b" {
  provider = aws.dr
  name     = "${var.project_name}-tg-b"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.b.id
  health_check {
    path = "/"
    port = "80"
  }
}
resource "aws_lb_listener" "b_http" {
  provider = aws.dr
  load_balancer_arn = aws_lb.b.arn
  port     = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.b.arn
  }
}
resource "aws_launch_template" "b" {
  provider      = aws.dr
  name_prefix   = "${var.project_name}-b-"
  image_id      = data.aws_ami.b.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  user_data     = local.user_data_b64
  network_interfaces { security_groups = [aws_security_group.b_app.id] }
}
resource "aws_autoscaling_group" "b" {
  provider            = aws.dr
  name                = "${var.project_name}-asg-b"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [for s in aws_subnet.b_private_app : s.id]
  launch_template {
    id      = aws_launch_template.b.id
    version = "$Latest"
  }
  target_group_arns   = [aws_lb_target_group.b.arn]
}
