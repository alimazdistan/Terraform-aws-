## 🎞 Terraform AWS Infrastructure Project

This Terraform project creates a complete web infrastructure on AWS, including a scalable EC2-based web application setup, EFS for shared storage, and an Application Load Balancer. It’s ideal for deploying a simple, highly available, and resilient web application.

---

### 🚀 What This Project Does

1. **Networking**
   - Creates a VPC (`10.0.0.0/16`) with two public subnets in different availability zones.
   - Adds an Internet Gateway and routes public traffic through it.

2. **Security**
   - Configures three Security Groups:
     - `alb_sg`: Allows inbound HTTP (port 80) traffic from the internet.
     - `ec2_sg`: Allows inbound HTTP traffic from the ALB and NFS traffic to EFS.
     - `efs_sg`: Allows inbound NFS (port 2049) traffic from EC2 instances.

3. **Elastic File System (EFS)**
   - Creates an EFS file system with mount targets in both subnets.
   - EFS is mounted on the EC2 instances to serve shared content.

4. **Launch Template**
   - Uses the latest Amazon Linux 2 AMI.
   - Installs Apache (`httpd`) and `amazon-efs-utils`.
   - Mounts EFS to `/var/www/html` and places a simple index page.

5. **Auto Scaling Group**
   - Creates an ASG with a desired capacity of 2 instances (min: 1, max: 3).
   - Launches EC2 instances in both public subnets using the defined launch template.
   - Automatically registers EC2 instances to the ALB target group.

6. **Application Load Balancer (ALB)**
   - Publicly accessible ALB that distributes HTTP traffic (port 80) across EC2 instances.
   - Configured with a listener and a target group for traffic forwarding.

7. **Outputs**
   - Prints the public DNS name of the Load Balancer.
   - Prints the EFS ID.

---

### 📟 Requirements

- Terraform >= 1.0
- AWS CLI configured
- SSH key pair in your AWS account (`mykey` used in this example)

---


### 📌 Notes

- Make sure the SSH key name (`mykey`) exists in your AWS region, or update it in the launch template block.
- The EC2 instances and ALB are created in `us-east-1` region by default.

