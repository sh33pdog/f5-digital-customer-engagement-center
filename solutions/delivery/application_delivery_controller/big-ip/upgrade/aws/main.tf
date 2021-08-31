# Main

# Terraform Version Pinning
terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = "~> 3"
  }
}

# AWS Provider
provider "aws" {
  region = var.awsRegion
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}

resource "random_id" "id" {
  byte_length = 2
}

resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Network
module "aws_network" {
  source                  = "../../../../../../modules/aws/terraform/network/min"
  projectPrefix           = var.projectPrefix
  awsRegion               = var.awsRegion
  map_public_ip_on_launch = true
}

# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf_ansible_vars_file" {
  content  = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    route_table: ${aws_route_table.main.id}
    storage_bucket: ${aws_s3_bucket.main.arn}
    public_vip_pip: ${aws_eip.vip-pip.public_ip}
    f5vm01_mgmt_private_ip: ${aws_network_interface.vm01-mgmt-nic.private_ip}
    f5vm01_mgmt_private_dns: ${aws_instance.f5vm01.private_dns}
    f5vm01_mgmt_public_ip: ${aws_eip.vm01-mgmt-pip.public_ip}
    f5vm01_ext_private_ip: ${aws_network_interface.vm01-ext-nic.private_ip}
    f5vm01_ext_secondary_ip: ${local.vm01_vip_ips.app1.ip}
    f5vm01_int_private_ip: ${aws_network_interface.vm01-int-nic.private_ip}
    f5vm02_mgmt_private_ip: ${aws_network_interface.vm02-mgmt-nic.private_ip}
    f5vm02_mgmt_private_dns: ${aws_instance.f5vm02.private_dns}
    f5vm02_mgmt_public_ip: ${aws_eip.vm02-mgmt-pip.public_ip}
    f5vm02_ext_private_ip: ${aws_network_interface.vm02-ext-nic.private_ip}
    f5vm02_ext_secondary_ip: ${local.vm02_vip_ips.app1.ip}
    f5vm02_int_private_ip: ${aws_network_interface.vm02-int-nic.private_ip}
    username: ${var.f5_username}
    generated_password: ${random_string.password.result}
    DOC
  filename = "./tf_ansible_vars_file.yml"
}

resource "null_resource" "run_ansible" {
  depends_on = [time_sleep.wait_420_seconds]
  provisioner "local-exec" {
    command = "ansible-playbook ansible/playbooks/demo.yml"
  }
}

resource "time_sleep" "wait_420_seconds" {
  depends_on      = [aws_instance.f5vm01, aws_instance.f5vm02]
  create_duration = "420s"
}
