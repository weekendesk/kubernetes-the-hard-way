resource "aws_key_pair" "admin" {
  key_name   = "admin.${var.suffix}"
  public_key = "${var.admin_public_key}"
}
