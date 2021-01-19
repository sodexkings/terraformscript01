
# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
}

# configure the UAT VPC
resource "aws_vpc" "uatvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "uat-vpc"
  }
}


resource "aws_subnet" "public-uat" {
  vpc_id     = aws_vpc.uatvpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-uat"
  }
}

resource "aws_subnet" "private-uat" {
  vpc_id     = aws_vpc.uatvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private-uat"
  }
}

resource "aws_internet_gateway" "uat-igw" {
  vpc_id = aws_vpc.uatvpc.id

  tags = {
    Name = "uat-igw"
  }
}



resource "aws_route_table" "uat-routable" {
  vpc_id = aws_vpc.uatvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.uat-igw.id
  }

  tags = {
    Name = "uat-routable"
  }
}


resource "aws_route_table_association" "association1" {
  subnet_id      = aws_subnet.public-uat.id
  route_table_id = aws_route_table.uat-routable.id
}


resource "aws_route_table_association" "association2" {
  subnet_id      = aws_subnet.private-uat.id
  route_table_id = aws_route_table.uat-routable.id
}

resource "aws_security_group" "sg-ssh" {
  name        = "sg_ssh"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.uatvpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ssh"
  }
}


resource "aws_instance" "uat-publicserver1" {
  ami           = "ami-000db10762d0c4c05"
  instance_type = "t2.micro"
  key_name = "mykpair_01"
  security_groups = [aws_security_group.sg-ssh.id]
  subnet_id = aws_subnet.public-uat.id

 tags = {
    Name = "uat-publicserver1"
  }
}

