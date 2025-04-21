provider "aws" {
  region = "us-east-1"
}

############################
# 1. NETWORK
############################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id
}

############################
# 2. SECURITY GROUP
############################

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP, SSH, NFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for test"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# 3. EFS
############################

resource "aws_efs_file_system" "efs" {
  performance_mode = "generalPurpose"
}

resource "aws_efs_mount_target" "efs_mount1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.web_sg.id]
}

resource "aws_efs_mount_target" "efs_mount2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet2.id
  security_groups = [aws_security_group.web_sg.id]
}

############################
# 4. LAUNCH TEMPLATE
############################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "mykey"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils httpd
              systemctl start httpd
              mount -t efs ${aws_efs_file_system.efs.id}:/ /var/www/html
              echo "${aws_efs_file_system.efs.id}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
              echo "Hello from EC2 via Auto Scaling!" > /var/www/html/index.html
              EOF
            )
}

############################
# 5. AUTO SCALING GROUP
############################

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

############################
# 6. LOAD BALANCER
############################

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups    = [aws_security_group.web_sg.id]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

############################
# 7. OUTPUT
############################

output "load_balancer_dns" {
  value = aws_lb.web_alb.dns_name
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}
