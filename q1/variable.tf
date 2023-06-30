variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.3.4.0/24", "10.3.5.0/24", "10.3.6.0/24"]
}

variable "az" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}
