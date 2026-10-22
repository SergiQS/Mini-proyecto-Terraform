provider "aws" {
    region  = var.region 
}

#VPC
resource  "aws_vpc" "main"{

cidr_block = var.vpc_cidr 
enable_dns_support = true
enable_dns_hostnames = true 

tags = {
  Name = "mini_vpc"
}
  
}

#Subnet publica 
resource "aws_subnet" "public" {
    vpc_id           = aws_vpc.main.id 
    cidr_block       = var.subnet_cidr
    map_public_ip_on_launch = true
    availability_zone = "${var.region}a"

    tags = {
        Name = "mini-public-subnet"
    }
}
 #Internet Gateaway (para que la subnet sepa por donde salir)
 resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    
}
 
 # Route table + asociacion 
 resource "aws_route_table" "public" {
   vpc_id = aws_vpc.main.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
   
    }
 }

 resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
   
 }

 # Security Group: Solo shh desde tu ip 
 resource "aws_security_group" "ssh" {
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port = 0 
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
   
 }
  resource "aws_subnet" "private" {
    vpc_id           = aws_vpc.main.id 
    cidr_block       = var.private_subnet_cidr
    
    availability_zone = "${var.region}a"

    tags = {
        Name = "mini-private-subnet"
    }
    
  }
  # Route table + asociacion 
 resource "aws_route_table" "private" {
   vpc_id = aws_vpc.main.id
 }

 resource "aws_route_table_association" "private" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
   
 }
 # AMI más reciente de Ubuntu
 data "aws_ami" "ubuntu"{
    most_recent = true
    owners = ["099720109477"]  # Canonical, el dueño oficial de las AMIs de Ubuntu

    filter {
      name = "name"
      values = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" ]
    }
 }
 #Key pair para SSH
resource "aws_key_pair" "deployer" {
    key_name = "mini-terraform-key"
    public_key = file("C:/Users/sergi/Desktop/KeysProyectos/mini-terraform-key.pub")
  
}

#Instacia EC2
 resource "aws_instance" "mini-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "mini-server"
  }
}
