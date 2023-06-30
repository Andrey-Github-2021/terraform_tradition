terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.3.0.0/16"

    tags ={
        Name = "main_VPC"
    }
}

#create 3 public

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs) 
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.public_subnet_cidrs, count.index)
    availability_zone = element(var.az, count.index)
    map_public_ip_on_launch = true

    tags = {
      Name = "Public Subnet ${count.index +1}"
    }
  
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Project gateway VPC"
 }
}

#route vpc to internet gateway
resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table"
 }
}

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}


# resource "aws_subnet" "private_subnets" {
#     count = length(var.private_subnet_cidrs)
#     vpc_id = aws_vpc.main.id
#     cidr_block = element(var.private_subnet_cidrs,count.index)
#     availability_zone = element(var.az,count.index)

#     tags = {
#         Name = "PrivateSubnet ${count.index +1}"
#     }
  
# }

#create security group

resource "aws_security_group" "instance" {
  name = "terraform_project"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

#creating launch configuration

resource "aws_launch_configuration" "terraform_launchconf" {
  image_id = "ami-0b1217c6bff20e276"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.instance.id ]
  associate_public_ip_address = "true"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo chmod 777 /var/www/html
              
              EOF
  lifecycle {
    create_before_destroy = true 
    }

}

#creating autocale group

resource "aws_autoscaling_group" "terraform_asg" {
  launch_configuration = aws_launch_configuration.terraform_launchconf.name

  min_size = 2
  max_size = 3

  vpc_zone_identifier = [ aws_subnet.public_subnets[0].id,aws_subnet.public_subnets[1].id,aws_subnet.public_subnets[2].id ]
  
  tag {
    key = "Name"
    value = "terraform_ASG"
    propagate_at_launch = true

  }
}

output "subnets_public_id" {
  value = [ aws_subnet.public_subnets[0].id,aws_subnet.public_subnets[1].id,aws_subnet.public_subnets[2].id ]
  description = "The public subnets"
}



