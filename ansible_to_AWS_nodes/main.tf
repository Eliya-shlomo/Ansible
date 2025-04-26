resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-gw"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.my_vpc.id 
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id 
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id 
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_assoc"{
  subnet_id = aws_subnet.public.id 
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "ssh" {
  name = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id = aws_vpc.my_vpc.id 

  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0 
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access"
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}



resource "aws_instance" "web" {
  count = 2
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.ssh.id]
  associate_public_ip_address = true
  key_name = "my-key" 


  tags = {
    Name = "web-server-${count.index}"
  }
}


output "instance_ips" {
  value = [for instance in aws_instance.web : instance.public_ip]
}