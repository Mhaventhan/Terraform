resource "aws_subnet" "mhaventhan-private" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "10.3.1.0/24"
  availability_zone = "eu-central-1a"
  tags {
    Name = "${var.name}-db-subnet"
  }
}
resource "aws_security_group" "mhaventhanDb" {
  name = "${var.name}-Db"
  description = "${var.name}Db Security Group"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "27017"
    to_port = "27017"
    protocol = "tcp"
    security_groups = ["${var.app_sgid}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-Db"
  }

}

resource "aws_network_acl" "db" {
    vpc_id = "${var.vpc_id}"

    ingress {
      from_port = 27017
      to_port = 27017
      protocol = "tcp"
      cidr_block = "${var.app_scb}"
      rule_no = 100
      action = "allow"
    }

    egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_block = "${var.app_scb}"
      action = "allow"
      rule_no = 120
    }
    subnet_ids = ["${aws_subnet.mhaventhan-private.id}"]

    tags {
      name = "${var.name}-db"
    }

}
resource "aws_route_table" "mhaventhan-Db"{
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}-dbRT"
  }
}
resource "aws_route_table_association" "db" {
  subnet_id      = "${aws_subnet.mhaventhan-private.id}"
  route_table_id = "${aws_route_table.mhaventhan-Db.id}"
}
resource "aws_instance" "mhaventhan-tf-db"{
  ami = "${var.ami_id}"
  subnet_id = "${aws_subnet.mhaventhan-private.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.mhaventhanDb.id}"]
  tags {
    Name = "mhav-TF-db"
  }
}
