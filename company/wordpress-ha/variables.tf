variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "title" {
  type = string
}

variable "admin_user" {
  type = string
}

variable "admin_email" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "host" {
  type = string
}

variable "enable_tls" {
  type    = bool
  default = false
}

variable "enable_multisite" {
  type    = bool
  default = false
}

variable "enable_debug" {
  type    = bool
  default = false
}

variable "cluster" {
  type = object({
    key_name          = string
    public_subnets       = list(string)
    private_subnets     = list(string)
    instance_image_id = string
    min_size          = optional(number, 1)
    max_size          = optional(number, 1)
    desired_size      = optional(number, 1)
    instance_type     = optional(string, "t3.micro")
  })
}

variable "db" {
  type = object({
    subnets                     = list(string)
    pass_length                 = optional(number, 32)
    pass_special                = optional(bool, false)
    pass_override_special       = optional(string, "@#&()+-_")
    allocated_storage           = optional(string, 5)
    max_allocated_storage       = optional(string, 100)
    engine                      = optional(string, "mysql")
    engine_version              = optional(string, "8.0")
    primary_instance_class      = optional(string, "db.t3.micro")
    username                    = optional(string, "main")
    port                        = optional(number, 3306)
    read_timeout                = optional(string, "30m")
    backup_retention_period     = optional(number, 7)
    backup_window               = optional(string, "03:00-04:00")
    maintenance_window          = optional(string, "sat:05:00-sat:06:00")
    skip_final_snapshot         = optional(bool, true)
    enable_multi_az             = optional(bool, true)
    enable_performance_insights = optional(bool, true)
    enable_apply_immediately    = optional(bool, true)
    storage_type                = optional(string, "gp2")
  })

}
