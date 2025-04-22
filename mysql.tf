
resource "aws_security_group" "internal_sg" {
  name        = "internal-access"
  description = "Allow access only from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  

  tags = {
    Name = "internal-sg"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "mysql" {
  identifier         = "mysql-db"
  engine             = "mysql"
  instance_class     = "db.t3.micro"
  username           = "admin"
  password           = "Password123!" # secret is better
  allocated_storage  = 20
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.internal_sg.id]
  skip_final_snapshot = true
  publicly_accessible = false
  tags = {
    Name = "mysql-db"
  }
}
output "rds_endpoint" {
  value = aws_db_instance.mysql.address
  description = "MySQL RDS endpoint"
}
