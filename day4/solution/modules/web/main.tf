data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ---------------------------------------------------------------
# Launch Template: 서버를 찍어 내는 "틀"
# ---------------------------------------------------------------
resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-lt-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.web_sg_id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    app_version = var.app_version
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-web", Course = "tf4d", Day = "day4" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------
# ALB + Target Group + Listener
# ---------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  deregistration_delay = 30 # 서버를 빼기 전 기다리는 시간(초). 실습이라 짧게

  health_check {
    path                = "/"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ---------------------------------------------------------------
# Auto Scaling Group: 틀(Launch Template)로 서버 수를 유지
# ---------------------------------------------------------------
resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg"
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  target_group_arns         = [aws_lb_target_group.this.arn]
  health_check_type         = "ELB" # ALB 헬스 체크에 실패하면 서버 교체
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  # 틀(Launch Template)이 바뀌면 서버를 절반씩 차례로 교체 (무중단 배포)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }

  lifecycle {
    # 오토 스케일링이 바꾼 서버 수를 Terraform이 되돌리지 않게
    ignore_changes = [desired_capacity]
  }
}
