variable "terraform_state_bucket" {
  type    = string
  default = "tfstate-cloud-carbon-footprint"
}

variable "default_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-053248ab91d350dd6" # Default VPC #
}

variable "ami_id" {
  type    = string
  default = "ami-0953476d60561c955" # Amazon Linux 2023 (64-bit (x86)) #
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "key_name" {
  type    = string
  default = "cloud-carbon-footprint-key-pair"
}

variable "private_subnet_id" {
  type    = string
  default = "subnet-0a07c535f1c34c91b" # Public Subnet us-east-1f #
}

variable "private_ip" {
  type    = string
  default = "172.30.5.129"
}

/*
# If you have a security group that allows inbound traffic to connections coming from within a VPN
variable "vpn_security_group_id" {
  type    = string
  default = "YOUR-VPN-SECURITY-GROUP-ID"
}
*/

variable "application" {
  type    = string
  default = "ccf"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "dns_name" {
  type    = string
  default = "ccf"
}

# This might be useful if you wanna restrict traffic to private subnets
variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["189.62.46.79/32","73.143.110.182/32"] # Anaue and Chris public IPs #
}
