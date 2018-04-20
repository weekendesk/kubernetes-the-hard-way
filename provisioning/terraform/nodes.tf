module "masters" {
  source = "./modules/masters"

  suffix              = "${var.suffix}"
  number_of_instances = "1"
  ami                 = "${var.ami}"

  sg_ids        = ["${list(aws_security_group.internal_traffic.id, aws_security_group.ssh.id, aws_security_group.devs.id)}"]
  subnet_id     = "${aws_subnet.cluster_instances.id}"
  key_pair_name = "${aws_key_pair.admin.key_name}"
}

module "workers" {
  source = "./modules/workers"

  ami                 = "${var.ami}"
  suffix              = "${var.suffix}"
  number_of_instances = "3"
  sg_ids              = ["${list(aws_security_group.internal_traffic.id, aws_security_group.ssh.id, aws_security_group.devs.id)}"]
  subnet_id           = "${aws_subnet.cluster_instances.id}"
  key_pair_name       = "${aws_key_pair.admin.key_name}"
}
