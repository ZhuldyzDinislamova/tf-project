variable "ami" {
  description = "(Required) The AMI to use for the instance."
}

variable "instance_type" {
  description = "(Required) The type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance."
  default     = "t2.micro"
}

variable "key_name" {
  description = "(Optional) The key name of the Key Pair to use for the instance; which can be managed using the aws_key_pair resource."
}

variable "vpc_security_group_ids" {
  description = "(Optional, VPC only) A list of security group IDs to associate with."
  default     = []
}

variable "subnet_id" {
  description = "(Optional) The VPC Subnet ID to launch in."
}

variable "associate_public_ip_address" {
  description = "(Optional) Associate a public ip address with an instance in a VPC. Boolean value."
  default     = true
}

variable "root_volume_type" {
  description = "(Optional) The type of volume. Can be 'standard', 'gp2', 'io1', 'sc1', or 'st1'. (Default: 'standard')."
  default     = "gp2"
}

variable "root_volume_size" {
  description = "(Optional) The size of the volume in gibibytes (GiB)."
  default     = "8"
}

variable "root_volume_delete_on_termination" {
  description = "(Optional) Whether the volume should be destroyed on instance termination (Default: true)."
  default     = true
}

variable "root_volume_encrypted" {
  description = "(Optional) Enables EBS encryption on the volume (Default: false). Cannot be used with snapshot_id. Must be configured to perform drift detection."
  default     = false
}

variable "user_data" {
 default = <<EOF
  #!/bin/bash
  yum update -y
  yum install httpd -y
  echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
  systemctl start httpd
  systemctl enable httpd
  EOF
}

variable "ec2_name" {}
