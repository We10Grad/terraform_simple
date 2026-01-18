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

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data = #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              echo "Hello, World!" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx

  tags = {
    Name = "HelloWorld"
  }
}