variable "vpc_id" {
description = "the vpc to launch the resources"
}

variable "name" {
description = "the name of the user"
}

variable "user_data" {
  description = "the user data to provide to the instance"
}

variable "ig_id" {
  description = "the ig to attach to route table"

}

variable "ami_id" {
  default = "The ami id for the app"
}
