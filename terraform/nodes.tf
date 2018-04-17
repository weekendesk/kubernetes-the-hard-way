locals {
  ami_id = "ami-70054309"
}

module "masters" {
  source = "./modules/masters"

  suffix              = "${var.suffix}"
  number_of_instances = "1"
  ami                 = "${local.ami_id}"
  sg_ids              = ["${aws_security_group.internal_traffic.id}"]
  subnet_id           = "${aws_subnet.cluster_instances.id}"
  key_pair_name       = "${aws_key_pair.admin.key_name}"
}

module "workers" {
  source = "./modules/workers"

  ami                 = "${local.ami_id}"
  suffix              = "${var.suffix}"
  number_of_instances = "3"
  sg_ids              = ["${aws_security_group.internal_traffic.id}"]
  subnet_id           = "${aws_subnet.cluster_instances.id}"
  key_pair_name       = "${aws_key_pair.admin.key_name}"
}
