region                = "ap-south-1"
vpc_id                = "vpc-08fe576ccbe2b287c"
subnet_id             = "subnet-0d3994719054640c3"
ami_prefix            = "scdt-gh-runner-2204"
ssh_public_key        = "/Users/piyushshrivastava/.ssh/packer/packer-linux-ssh.pub"
ssh_private_key_file  = "/Users/piyushshrivastava/.ssh/packer/packer-linux-ssh"
packer_security_group = "sg-018f7bb468fd97d2b"
instance_type         = "m6a.large"
ami_base_image_name   = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
volume_size           = 8
volume_type           = "gp3"
iam_instance_profile  = "packer-ssm-role"

