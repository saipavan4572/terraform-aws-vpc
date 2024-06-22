#### project variables ####
variable "project_name" {
    type = string
## here we are not providing the default and forced user to provide their respective project_name
}

variable "environment" {
    type = string
    default = "dev"
## here we can set the default value as dev or we can force user to provide
}

variable "common_tags" {
    type = map
}

#### vpc variables ####
variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
  
}

variable "enable_dns_hostnames" {
    type = bool
    default = true 
}

variable "vpc_tags" {
    type = map
    default = {}
}

#### IGW variables ####
variable "igw_tags"{
    type = map
    default = {}
}

### Public Subnet ####
variable "public_subnet_cidrs" {
    type = list
    validation {
        #adding a condition to have only 2 subnets
        condition = length(var.public_subnet_cidrs) == 2
        #condition is not satisfied(<2 or >2) then, error message
        error_message = "Please provide 2 valid public subnet CIDR"
    }
}

variable "public_subnet_cidr_tags" {
    type = map
    default = {}
}