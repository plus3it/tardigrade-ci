variable "mockstack_host" {
  description = "Hostname for mock AWS endpoint"
  type        = string
  default     = "localhost"
}

variable "mockstack_port" {
  description = "Port for mock AWS endpoint"
  type        = string
  default     = "4566"
}

# Port 4615 was chosen to be used for moto because that port is used by
# LocalStack for the organizations service.  We'll piggyback onto that
# port for other moto-specific services.
variable "moto_port" {
  description = "Port for moto; for services not provided by LocalStack"
  type        = string
  default     = "4615"
}
