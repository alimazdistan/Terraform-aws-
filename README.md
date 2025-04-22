# ☁️ Terraform AWS Infrastructure Project

This Terraform project builds a secure and scalable AWS network architecture with **two public subnets** and **two private subnets**, each distributed across **two Availability Zones** in the `eu-central-1` region. EC2 instances are deployed in the **private subnets**, and access the internet through a **NAT Gateway** for downloading packages and system updates. An **Application Load Balancer (ALB)** is placed in the **public subnets**, routing external traffic to the EC2 instances behind it. The compute layer is managed by an **Auto Scaling Group**, which scales up or down automatically based on **CloudWatch CPU alarms**.

We provisioned backend services including **MySQL (RDS)**, **Memcached (ElastiCache)**, and **ActiveMQ (Amazon MQ)**, all inside the private subnets and only accessible by the EC2 instances — ensuring full isolation from the public internet. The ALB is the only public entry point and cannot access internal resources directly.

Additionally, an **EFS (Elastic File System)** is created and automatically mounted to a specific web server folder inside the EC2 instances via user-data scripts. This setup is ideal for shared configuration, file uploads, or logs across multiple instances.

This architecture ensures **security, scalability, and high availability** across multiple availability zones in the `eu-central-1` region.

---

## 🧱 Architecture Overview

The infrastructure is based on a **highly available and scalable microservices architecture**, deployed across **two Availability Zones** in `eu-central-1`.

### 🔹 VPC & Networking

- A custom **VPC** with:
  - 2 **Public Subnets** across 2 AZs (for NAT Gateway and Load Balancer)
  - 2 **Private Subnets** across 2 AZs (for backend resources like EC2, RDS, etc.)
- **Internet Gateway** for public access to the ALB
- **NAT Gateway** allows private subnets to access the internet securely
- **Route Tables** handle internal and external traffic routing

### 🔹 Compute: EC2 + Auto Scaling

- An **Auto Scaling Group** (ASG) launches EC2 instances based on CPU usage:
  - Min: 1, Max: 3 (customizable)
  - Each instance runs **NGINX**
  - Each instance mounts **Amazon EFS** to share configuration or persistent data
- The ASG is attached to an **Application Load Balancer (ALB)**:
  - Distributes traffic evenly to healthy EC2 instances
  - Performs health checks and ensures zero-downtime scaling

### 🔹 Storage & Databases

- **Amazon RDS (MySQL)**:
  - Managed MySQL database deployed in a private subnet
  - Only accessible by EC2 instances via Security Groups

- **Amazon ElastiCache (Memcached)**:
  - Provides in-memory caching for performance improvements
  - Accessible only from inside the VPC

- **Amazon EFS (Elastic File System)**:
  - Shared file storage mounted across all EC2 instances
  - Suitable for logs, configs, user uploads, etc.

### 🔹 Messaging & Queueing

- **Amazon MQ (ActiveMQ)**:
  - Used as a message broker for inter-service communication
  - Runs in **SINGLE_INSTANCE** mode and private subnet


### 🔹 Monitoring & Scaling

- **Amazon CloudWatch**:
  - Monitors EC2 CPU usage and triggers alarms
  - Auto Scaling policies:
    - Scale out when CPU > 70%
    - Scale in when CPU < 20%
  - Logs and metrics can be extended to other services

### 🔹 Security

- Multiple **Security Groups** with least-privilege rules:
  - EC2 instances can access RDS, MQ, Cache, EFS
  - No service is publicly exposed except the ALB

---

## 📦 Terraform Outputs

- ALB DNS name
- MySQL RDS endpoint
- Memcached endpoint
- ActiveMQ endpoint
- EFS DNS name


---

## 🚀 Usage

```bash
terraform init
terraform plan
terraform apply
```



 


