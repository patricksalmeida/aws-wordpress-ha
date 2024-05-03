variable "vpc_id" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "igw_id" {
  type    = string
  default = null
}

variable "nat_gateway_subnet_id" {
  type    = string
  default = null
}

variable "identifier" {
  type = string
}

variable "public" {
  type    = bool
  default = false
}
