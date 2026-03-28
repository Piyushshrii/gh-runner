region                = "ap-south-1"
vpc_id                = "vpc-xxxxxxxxxxxxx"
subnet_id             = "subnet-0d3994719054640c3"
ami_prefix            = "scdt-gh-runner-2204"
ssh_public_key        = "ssh_pub_key_path_in_your_local"
ssh_private_key_file  = "ssh_private_key_path_in_your_local""
packer_security_group = "sg-xxxxxxxxxxxxxx"
instance_type         = "m6a.large"
ami_base_image_name   = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
volume_size           = 8
volume_type           = "gp3"
iam_instance_profile  = "github-runner-role"

