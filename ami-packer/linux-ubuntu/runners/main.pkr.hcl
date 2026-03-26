packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Local Values
locals {
  timestamp = formatdate("YYYYMMDD-HHmmss", timestamp())
}


# Source AMI
source "amazon-ebs" "ubuntu2204" {
  region = var.region

  instance_type = var.instance_type
  communicator  = "ssh"
  ssh_interface = "session_manager"
  ssh_username  = "ubuntu"

  iam_instance_profile = var.iam_instance_profile

  # BASE AMI
  source_ami_filter {
    filters = {
      name                = var.ami_base_image_name
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = false

  # Attach a security group with no inbound rules
  security_group_ids = [var.packer_security_group]

  # AMI CONFIG
  ami_name        = "${var.ami_prefix}-${local.timestamp}"
  ami_description = "Non Production Ubuntu 22.04 LTS"

  encrypt_boot = true

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
  }

  user_data = <<-EOF
  #!/bin/bash

  # Setup SSH keys for ubuntu user
  SSH_DIR="/home/ubuntu/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  chown ubuntu:ubuntu "$SSH_DIR"

  # Inject public key from file variable
  echo "${file(var.ssh_public_key)}" >> "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
  chown ubuntu:ubuntu "$SSH_DIR/authorized_keys"

  # Restart SSH
  systemctl restart ssh
  EOF

  tags = {
    OS        = "Ubuntu2204"
    CreatedBy = "Packer"
  }
}

# Build Configuration
build {

  name    = "ubuntu-2204-build"
  sources = ["source.amazon-ebs.ubuntu2204"]

  provisioner "shell" {
    script = "scripts/install-tools.sh"
  }

  provisioner "shell" {
    script = "scripts/linux-updates.sh"
  }

  provisioner "shell" {
    script = "scripts/sysprep.sh"
  }

  provisioner "shell" {
    script = "scripts/gh-runner-register.sh"
  }
}


