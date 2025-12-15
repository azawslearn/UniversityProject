variable "location" {
  type        = string
  description = "The Azure region to deploy resources"
  default     = "East US"
}

variable "dc_password" {
  type        = string
  description = "password for the administrator of the DC"
  default     = "EmersonFitipaldi2023!"
}

variable "dc_size" {
  type        = string
  description = "size of the image of the DC"
  default     = "Standard_B2ms"
}

variable "exchange_size" {
  type        = string
  description = "size of the image of the client machine"
  default     = "Standard_B2ms"
}

variable "dc_password_new" {
  type        = string
  description = "password for joining"
  default     = "1"
}