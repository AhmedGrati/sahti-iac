variable "default_subnet_a_id" {
}
variable "default_subnet_b_id" {
}
variable "default_subnet_c_id" {
}
variable "alb_target_group_arn" {
}
variable "alb_listener_id" {
}
variable "vpc_id" {
}
variable "api_port" {
  default = "4000"
}
variable "postgres_username" {
  sensitive = true
}
variable "postgres_password" {
  sensitive = true
}
variable "postgres_db" {
  default = "sahti"
}
variable "postgres_port" {
  default = "5432"
}
variable "redis_port" {
  default = "6379"
}
variable "jwt_verif_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_verif_token_expir_time" {
  default = "21600"
}
variable "jwt_login_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_login_token_expir_time" {
  default = "21600"
}
variable "jwt_refresh_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_refresh_token_expir_time" {
  default = "21600"
}
variable "jwt_reset_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
