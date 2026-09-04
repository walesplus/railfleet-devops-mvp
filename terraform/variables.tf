variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "railfleet"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Set to a trusted address only."
}

variable "allowed_web_cidr" {
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
