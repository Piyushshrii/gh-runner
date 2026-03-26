variable "region" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "ami_base_image_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 8
}
variable "volume_type" {
  description = "Type of the EBS volume (gp3)"
  type        = string
}
variable "vpc_id" {
  description = "VPC ID where the Packer EC2 Builder instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the Packer EC2 Builder instance will be launched"
  type        = string
}

variable "ami_prefix" {
  description = "Prefix for the AMI name"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to the public SSH key file"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to the private SSH key file"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for the Packer EC2 Builder instance (with SSM permissions)"
  type        = string
  default     = null
}
variable "packer_security_group" {
  description = "Security group ID for the  Packer EC2 Builder instance (no inbound, outbound 443 & 80for SSM)"
  type        = string
}
