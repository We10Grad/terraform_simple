# Create an Ec2 instance with a specific AMI and instance type

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create an EC2 instance that runs a simple web server
resource "aws_instance" "example" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  user_data       = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              echo "Hello, World!" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  security_groups = [aws_security_group.terraform_project_sg.name]
  key_name        = aws_key_pair.terraform_project_key.key_name

  tags = {
    Name = "TerraformExampleInstance"
  }
}

# Create a security group that allows HTTP and SSH inbound traffic and all outbound traffic
resource "aws_security_group" "terraform_project_sg" {
  name        = "terraform_project_sg"
  description = "Allow HTTP and SSH inbound traffic and all outbound traffic"

  tags = {
    Name = "terraform_project_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.terraform_project_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.terraform_project_sg.id
  cidr_ipv4         = "73.228.206.20/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.terraform_project_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Create an SSH key pair to access the EC2 instance
resource "aws_key_pair" "terraform_project_key" {
  key_name   = "terraform_project_key"
  public_key = file("~/.ssh/aws_terraform_key.pub")
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.example.id
}

output "instance_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.example.private_ip
}
