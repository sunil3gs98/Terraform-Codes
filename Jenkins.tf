provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_subnet" "sunil" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sunil.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "jenk" {
  vpc_id = aws_vpc.test.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Jenkins" {
  ami                  = "ami-0ad21ae1d0696ad58"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.sunil.id
  vpc_security_group_ids = [aws_security_group.jenk.id]

  tags = {
    Name = "Jenkins"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install fontconfig openjdk-17-jre -y
    sudo apt-get install jenkins -y-y-y
  EOF
}

output "jenkins_url" {
  value = "http://${aws_instance.Jenkins.public_ip}:8080"
}
