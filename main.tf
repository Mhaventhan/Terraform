provider "aws" {
region = "eu-central-1"
}

# 1 - terraform init
module "app" {
  source = "./modules/app_tier"
  vpc_id = "${aws_vpc.mhaventhan.id}"
  name = "Mhav-app"
  user_data = "${data.template_file.app_init.rendered}"
  ig_id = "${aws_internet_gateway.mhaventhan.id}"
  ami_id = "${var.app_ami_id}"
}

module "db" {
  source = "./modules/db_tier"
  vpc_id = "${aws_vpc.mhaventhan.id}"
  name = "Mhav-DB"
  user_data = "${data.template_file.app_init.rendered}"
  app_sgid = "${module.app.security_group_id}"
  app_scb = "${module.app.subnet_cidr_block}"
  ami_id = "${var.db_ami_id}"
}

resource "aws_vpc" "mhaventhan" {
  cidr_block = "10.3.0.0/16"
  tags{
    Name = "mhaventhan-TF-vpc"
  }
}

resource "aws_internet_gateway" "mhaventhan"{
  vpc_id = "${aws_vpc.mhaventhan.id}"

  tags{
    Name = "mhaventhan-TF-IG"
  }
}

data "template_file" "app_init" {
  template = "${file("./scripts/app/setup.sh.tpl")}"

  vars {
    db_host="mongodb://${module.db.db_instance}:27017/posts"

  }
}

resource "aws_lb" "lb" {
  name = "Mhav-lb-TF"
  internal = false
  load_balancer_type = "network"
  subnets = ["${module.app.subnet_app_id}"]
  enable_deletion_protection = false
  tags {
    Name = "Mhav_App_Lb"
  }

}

#Auto scaling laucnh configuration
resource "aws_launch_configuration" "Mhav-App-LCF" {
  name          = "${var.name}-tf-lCF"
  image_id      = "${var.app_ami_id}"
  instance_type = "t2.micro"
  security_groups = ["${module.app.security_group_id}"]
  user_data = "${data.template_file.app_init.rendered}"
  lifecycle {
         create_before_destroy = true
  }
}

#Auto Scaling groups
resource "aws_autoscaling_group" "app" {
  name                      = "Mhav-App-AS"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.Mhav-App-LCF.name}"
  vpc_zone_identifier       = ["${module.app.subnet_app_id}"]
  target_group_arns = ["${aws_lb_target_group.MhavApp.id}"]
  lifecycle {
         create_before_destroy = true
  }

}

resource "aws_lb_target_group" "MhavApp" {
  name = "${var.name}-target-group"
  port = "80"
  protocol = "TCP"
  vpc_id = "${aws_vpc.mhaventhan.id}"
}
resource "aws_lb_listener" "mhaventhanapp" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.MhavApp.arn}"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "Z3CCIZELFLJ3SC"
  name    = "example.com"
  type    = "A"

  alias {
    name                   = "${aws_lb.lb.dns_name}"
    zone_id                = "${aws_lb.lb.zone_id}"
    evaluate_target_health = true
  }
}
