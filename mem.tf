

# Security Group Memcached
resource "aws_security_group" "app_mem" {
  name        = "app-sg"
  description = "Allow  traffic for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 11211
    to_port         = 11211
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

 
}

# ElastiCache Memcached
resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = "memcached-cluster"
  engine               = "memcached"
  engine_version       = "1.6.17"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 11211
  subnet_group_name    = aws_elasticache_subnet_group.mem_subnet_group.name
  security_group_ids   = [aws_security_group.app_mem.id]

  tags = {
    Name = "Memcached"
  }
}

resource "aws_elasticache_subnet_group" "mem_subnet_group" {
  name       = "mem-subnet-group"
  subnet_ids = [aws_subnet.private_a.id,aws_subnet.private_b.id]
}

# Security Group Amazon MQ ActiveMQ
resource "aws_security_group" "app_active" {
  name        = "app-active"
  description = "Allow  traffic for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 61617
    to_port         = 61617
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

 
}

# Amazon MQ ActiveMQ
resource "aws_mq_broker" "activemq" {
  broker_name         = "activemq-broker"
  engine_type         = "ActiveMQ"
  engine_version      = "5.17.6"
  host_instance_type  = "mq.t3.micro"
  publicly_accessible = true
  subnet_ids          = [aws_subnet.private_a.id]
  security_groups     = [aws_security_group.app_active.id]

  user {
    username = "admin"
    password = "VerySecurePassword123!"
  }

  tags = {
    Name = "ActiveMQ"
  }
}

output "memcached_endpoint" {
  value = aws_elasticache_cluster.memcached.cache_nodes[0].address

  description = "Memcached endpoint"
}
output "activemq_endpoint" {
  value = aws_mq_broker.activemq.instances[0].endpoints[0]
  description = "ActiveMQ broker endpoint"
}

