terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region = var.aws-region
}

module "vpc" {
  source           = "./modules/vpc"
  default_subnet_a = var.default_subnet_a
  default_subnet_b = var.default_subnet_b
  default_subnet_c = var.default_subnet_c
}

module "alb" {
  source              = "./modules/alb"
  default_subnet_a_id = module.vpc.default_subnet_a_id
  default_subnet_b_id = module.vpc.default_subnet_b_id
  default_subnet_c_id = module.vpc.default_subnet_c_id
  default_vpc_id      = module.vpc.default_vpc_id
}
module "ecs" {
  source               = "./modules/ecs"
  default_subnet_a_id  = module.vpc.default_subnet_a_id
  default_subnet_b_id  = module.vpc.default_subnet_b_id
  default_subnet_c_id  = module.vpc.default_subnet_c_id
  alb_target_group_arn = module.alb.alb_target_group_arn
  vpc_id               = module.vpc.default_vpc_id
  alb_listener_id      = module.alb.alb_listsner_id
  postgres_password    = var.postgres_password
  postgres_username    = var.postgres_username
}
