# APP
# Create a subnet
resource "aws_subnet" "mhaventhanApp" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "10.3.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
  tags {
    Name = "${var.name}-app-subnet"
  }
}
resource "aws_security_group" "mhaventhanApp" {
  name = "${var.name}"
  description = "${var.name} access"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name ="${var.name}-app"
  }
}

resource "aws_network_acl" "app" {
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 80
    to_port =  80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    action = "allow"
    rule_no = 100
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    action = "allow"
    rule_no = 100
  }

  # EPHEMERAL PORTS
  egress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no = 120
    action = "allow"
  }

  ingress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no = 120
    action = "allow"
  }

  subnet_ids = ["${aws_subnet.mhaventhanApp.id}"]

  tags {
    name = "${var.name}-TF-NACL"
  }

}

#public route table
resource "aws_route_table" "mhaventhanApp"{
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.ig_id}"
  }

  tags {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "app" {
  subnet_id      = "${aws_subnet.mhaventhanApp.id}"
  route_table_id = "${aws_route_table.mhaventhanApp.id}"
}

# launch an instance
resource "aws_instance" "mhav_TF_app"{
  ami = "${var.ami_id}"
  subnet_id = "${aws_subnet.mhaventhanApp.id}"
  vpc_security_group_ids = ["${aws_security_group.mhaventhanApp.id}"]
  instance_type = "t2.micro"
  user_data = "${var.user_data}"
  tags{
    Name = "${var.name}TF-app"
  }
}
