variable "region" {
  description = "AWS region"
  type = string
  default = "ap-south-1"
}

variable "ec2_instance_iam_role_name" {
  description = "IAM role name for EC2 instances (e.g., GitHub runners)"
  type = string
  default = ""
}

variable "ec2_runner_instance_type" {
  description = "EC2 instance type for GitHub runners"
  type = string
  default = "t3a.micro"
}

variable "ec2_runner_security_group_id" {
  description = "Security group ID for EC2 runners"
  type = list(string)
  default = ["sg-xxxxxxxxxxx"]
}

variable "vpc_subnet_id" {
  description = "Subnet IDs for EC2 runners"
  type = list(string)
  default = ["subnet-xxxxxxxxxxxx"]
}
