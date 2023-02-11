variable "db_subnet_group_name" {}

variable "db_security_group_id" {}

variable "username" {}

variable "password" {}

variable "allocated_storage" {
  type = number
}

variable "engine" {}

variable "engine_version" {}

variable "instance_class" {}

variable "db_name" {
  type = string
  }

variable "multi_az" {
  type = bool
}

variable "allow_major_version_upgrade" {
    type = bool
} 

variable "auto_minor_version_upgrade" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}