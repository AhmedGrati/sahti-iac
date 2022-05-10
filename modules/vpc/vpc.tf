resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = var.default_subnet_a
}
resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = var.default_subnet_b
}
resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = var.default_subnet_c
}