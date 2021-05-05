locals {
  allow_public_ip_cidr = var.my_public_ip == "" ? "0.0.0.0/0" : "${var.my_public_ip}/32"

  allow_from_web_and_bastion_sgs    = [ aws_security_group.bastion.id, aws_security_group.webserver.id ]
  allow_from_web_bastion_and_qs_sgs = [ aws_security_group.quicksight.id ]
}
