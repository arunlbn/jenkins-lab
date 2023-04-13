provider "aws" {
  region = var.awsregion
}



module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.project_name
  cidr = "10.0.0.0/16"

  azs             = var.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
    Environment = var.env_name
  }
}


module "mon_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.project_name
  description = "Security group for user-service with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "prometheus-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "graphana-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      description = "allow all traffic within vpc"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
 
 egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      description = "allow-all-outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}



module "node_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.project_name
  description = "Security group for user-service with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      description = "Nodeexporter ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      description = "allow all traffic within vpc"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

 egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      description = "allow-all-outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}



module "ec2_instancemon" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(var.srvsmon)

  name = "instance-${each.key}"

  ami                    = var.ami_id
  instance_type          = var.srv_type
  key_name               = var.srv_key
  monitoring             = false
  vpc_security_group_ids = [module.mon_service_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = var.env_name
  }
}


module "ec2_instancenode" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(var.srvsnode)

  name = "instance-${each.key}"

  ami                    = var.ami_id
  instance_type          = var.srv_type
  key_name               = var.srv_key
  monitoring             = false
  vpc_security_group_ids = [module.node_service_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = var.env_name
  }
}



