# call vpc module from local:
module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = "10.0.0.0/24"
  vpc_tag        = "vpc"
}

#subnet module "public-1a"
module "public-1a-subnet" {
  source                  = "./modules/subnet"
  vpc_id                  = module.vpc.vpc_id
  subnet_cidr_block       = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  subnet_tag              = "public-1a-subnet"
}

#subnet module "public-1b"
module "public-1b-subnet" {
  source                  = "./modules/subnet"
  vpc_id                  = module.vpc.vpc_id
  subnet_cidr_block       = "10.0.0.64/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  subnet_tag              = "public-1b-subnet"
}

#subnet module "private-1a"
module "private-1a-subnet" {
  source                  = "./modules/subnet"
  vpc_id                  = module.vpc.vpc_id
  subnet_cidr_block       = "10.0.0.128/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  subnet_tag              = "private-1a-subnet"
}

#subnet module "private-1b"
module "private-1b-subnet" {
  source                  = "./modules/subnet"
  vpc_id                  = module.vpc.vpc_id
  subnet_cidr_block       = "10.0.0.192/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  subnet_tag              = "private-1b-subnet"
}

#create Internet gateway
module "igw" {
  source  = "./modules/igw"
  vpc_id  = module.vpc.vpc_id
  igw_tag = "igw"
}

#create nat-gateway
module "natgw" {
  source    = "./modules/natgw"
  subnet_id = module.public-1a-subnet.subnet_id
  natgw_tag = "natgw"
}

#create public route table
module "public_rtb" {
  source         = "./modules/route_table"
  vpc_id         = module.vpc.vpc_id
  gateway_id     = module.igw.igw_id
  nat_gateway_id = null
  subnet_ids     = [module.public-1a-subnet.subnet_id, module.public-1b-subnet.subnet_id]
}

#create private route table
module "private_rtb" {
  source         = "./modules/route_table"
  vpc_id         = module.vpc.vpc_id
  gateway_id     = null
  nat_gateway_id = module.natgw.natgw_id
  subnet_ids     = [module.private-1a-subnet.subnet_id, module.private-1b-subnet.subnet_id]
}

# create security group for web server EC2s:
module "ec2_sg" {
  source  = "./modules/security_group"
  sg_name = "ec2-sg"
  vpc_id  = module.vpc.vpc_id

  rules = {
    "0" = ["ingress", "0.0.0.0/0", "22", "22", "TCP", "allow ssh from www"]
    #"second" = ["ingress", module.alb_sg.sg_id, "80", "80", "TCP", "allow http traffic from ALB"]
    "1" = ["egress", "0.0.0.0/0", "0", "65535", "-1", "allow outbound traffic to www"]
    "2" = ["ingress", module.alb_sg.sg_id, "80", "80", "TCP", "allow http traffic from ALB"]
    # "3" = ["ingress", "0.0.0.0/0", "100", "100", "TCP", "hello from tentech"]
  }
}

#create security group for ALB
module "alb_sg" {
  source  = "./modules/security_group"
  sg_name = "alb-sg"
  vpc_id  = module.vpc.vpc_id

  rules = {
    0 = ["ingress", "0.0.0.0/0", 80, 80, "TCP", "allow http from www"]
    1 = ["ingress", "0.0.0.0/0", 443, 443, "TCP", "allow https from www"]
    2 = ["egress", "0.0.0.0/0", 0, 65535, "-1", "allow outbound traffic to www"]
  }
}

# create db security group:
module "db_sg" {
  source  = "./modules/security_group"
  sg_name = "db-sg"
  # sg_tag  = "db_sg"
  vpc_id = module.vpc.vpc_id
  rules = {
    0 = ["ingress", module.ec2_sg.sg_id, 3306, 3306, "TCP", "allow http traffic from EC2"]
    1 = ["egress", "0.0.0.0/0", 0, 65535, "-1", "allow outbound traffic to www"]
  }
}

#data call for existing ssh key
data "aws_key_pair" "tentek" {
  key_name = "tentek"
}

# data for ec2 ami
data "aws_ssm_parameter" "ami" {
  name = "ami3"
}

# output "aws_ssm_parameter" {
#   value = data.aws_ssm_parameter.ami.value
#   sensitive = true
# }

#create ec2-instances
module "ec2-public-1a" {
  source                 = "./modules/ec2"
  ami                    = data.aws_ssm_parameter.ami.value
  key_name               = data.aws_key_pair.tentek.key_name
  vpc_security_group_ids = [module.ec2_sg.sg_id]
  subnet_id              = module.public-1a-subnet.subnet_id
  ec2_name               = "public-1a-ec2"
}

module "ec2-public-1b" {
  source                 = "./modules/ec2"
  ami                    = data.aws_ssm_parameter.ami.value
  key_name               = data.aws_key_pair.tentek.key_name
  vpc_security_group_ids = [module.ec2_sg.sg_id]
  subnet_id              = module.public-1b-subnet.subnet_id
  ec2_name               = "public-1b-ec2"
}

# create target group:
module "target_group" {
  source            = "./modules/target_group"
  target_group_name = "tf-target-group"
  port              = 80
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  instance_ids      = [module.ec2-public-1a.ec2_id, module.ec2-public-1b.ec2_id]
}

# # data call for ssl certificate:
data "aws_acm_certificate" "issued" {
  domain   = "zhuldyz.link"
  statuses = ["ISSUED"]
}

# create alb:
module "alb" {
  source           = "./modules/alb"
  alb_sg           = [module.alb_sg.sg_id]
  alb_subnets      = [module.public-1a-subnet.subnet_id, module.public-1b-subnet.subnet_id]
  target_group_arn = module.target_group.target_group_arn
  cert_arn         = data.aws_acm_certificate.issued.arn
}

# lookup hosted zone:
data "aws_route53_zone" "hosted_zone" {
  name         = "zhuldyz.link"
  private_zone = false
}

# create route53 CNAME record:
module "route53_record" {
  source  = "./modules/dns"
  zone_id = data.aws_route53_zone.hosted_zone.id
  type    = "CNAME"
  ttl     = "100"
  name    = "terraform_project.zhuldyz.link" # what to type in browser
  records = [module.alb.alb_dns_name]        # where it will take
}

# create rds subnet group:
module "subnet_group" {
  source    = "./modules/subnet_group"
  subnet_id = [module.private-1a-subnet.subnet_id, module.private-1b-subnet.subnet_id]
}


data "aws_secretsmanager_secret_version" "credentials" {
  secret_id = "rds_credentials"
}

locals {
  rds_credentials = jsondecode(
  data.aws_secretsmanager_secret_version.credentials.secret_string)
}

module "rds" {
  source                      = "./modules/database"
  username                    = local.rds_credentials.rds_username
  password                    = local.rds_credentials.rds_password
  db_security_group_id        = [module.ec2_sg.sg_id]
  db_subnet_group_name        = module.subnet_group.db_subnet_group_name
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "5.7.37"
  instance_class              = "db.t3.micro"
  db_name                     = "project_db"
  multi_az                    = false
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  skip_final_snapshot         = true
}

