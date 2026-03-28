data "aws_ami" "latest" {
  provider    = aws.src
  most_recent = true

  owners = ["self"]

  filter {
    name   = "name"
    values = ["gh-runner-2204*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Launch Template
resource "aws_launch_template" "runner" {
  provider = aws.src

  name_prefix   = "scdt-runner"
  image_id      = data.aws_ami.latest.id
  instance_type = var.ec2_runner_instance_type

  iam_instance_profile {
    name = var.ec2_instance_iam_role_name
  }

  network_interfaces {
    security_groups = var.ec2_runner_security_group_id
  }

  # user-data script
  user_data = base64encode(file("${path.module}/gh-runner.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "scdt-runner"
      Environment = "dev"
    }
  }
}

resource "aws_autoscaling_group" "runner_asg" {
  provider = aws.src

  name = "scdt-runner-asg"

  min_size         = 1   
  desired_capacity = 1
  max_size         = 4

  vpc_zone_identifier = var.vpc_subnet_id

  launch_template {
    id      = aws_launch_template.runner.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "runner"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-fast"
  autoscaling_group_name = aws_autoscaling_group.runner_asg.name

  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1

  cooldown = 0   
}

# SCALE IN (SLOW 🧊)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-slow"
  autoscaling_group_name = aws_autoscaling_group.runner_asg.name

  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = -1

  cooldown = 120   
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  provider            = aws.src
  alarm_name          = "runner-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.runner_asg.name
  }
}
