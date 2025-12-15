variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Prefix to be added to all Azure resource names."
  type        = string
  default     = "IMAP"
}

variable "vm_size" {
  description = "Size of the Ubuntu VM."
  type        = string
  default     = "Standard_B1s"
}
