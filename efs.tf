# Security Group 
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  

  tags = {
    Name = "efs-sg"
  }
}

# Create EFS
resource "aws_efs_file_system" "web_efs" {
  creation_token = "web-efs"
  tags = {
    Name = "web-efs"
  }
}

#  Mount Target  Subnet
resource "aws_efs_mount_target" "private_a" {
  file_system_id  = aws_efs_file_system.web_efs.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "private_b" {
  file_system_id  = aws_efs_file_system.web_efs.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs_sg.id]
}
