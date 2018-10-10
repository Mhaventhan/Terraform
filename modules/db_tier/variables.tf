variable "vpc_id" {
description = "the vpc to launch the resources"
}

variable "name" {
description = "the name of the user"
}

variable "user_data" {
  description = "the user data to provide to the instance"
}

variable "ami_id" {
  default = "The ami id for the app"
}

variable "app_sgid" {
  default = "security group for the app"
}

variable "app_scb" {
  default = "app subnet cidr block"
}
