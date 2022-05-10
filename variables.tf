variable "aws-region" {
  description = "This is the AWS region variable."
}
variable "default_subnet_a" {
}
variable "default_subnet_b" {
}
variable "default_subnet_c" {
}
variable "postgres_username" {
}
variable "postgres_password" {
}
variable "postgres_db" {
  default = "sahti"
}
variable "postgres_port" {
  default = 5432
}
variable "redis_port" {
  default = 6379
}
variable "jwt_verif_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_verif_token_expir_time" {
  default = 21600
}
variable "jwt_login_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_login_token_expir_time" {
  default = 21600
}
variable "jwt_refresh_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}
variable "jwt_refresh_token_expir_time" {
  default = 21600
}
variable "jwt_reset_token_secret" {
  default = "7AnEd5epXmdaJfUrokkQ"
}