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

resource "ansible_group" "masters" {
  inventory_group_name = "k8s_masters"
}

data "aws_instance" "masters" {
  count       = "${length(module.masters.instance_ids)}"
  instance_id = "${element(module.masters.instance_ids, count.index)}"
}

resource "ansible_host" "ansible_master_hosts" {
  count = "${length(data.aws_instance.masters.*.id)}"

  inventory_hostname = "${element(data.aws_instance.masters.*.public_ip, count.index)}"
  groups             = ["k8s_masters"]

  vars {
    ansible_user                 = "${var.admin_user}"
    ansible_ssh_private_key_file = "/home/mbenabda/.ssh/wed_mbenabda_rsa"
    host_key_checking            = false

    k8s_api_public_hostname_or_ip = "${aws_eip.k8s_api.public_ip}"
  }
}

resource "ansible_group" "workers" {
  inventory_group_name = "k8s_workers"
}

data "aws_instance" "workers" {
  count       = "${length(module.workers.instance_ids)}"
  instance_id = "${element(module.workers.instance_ids, count.index)}"
}

resource "ansible_host" "ansible_worker_hosts" {
  count = "${length(data.aws_instance.workers.*.id)}"

  inventory_hostname = "${element(data.aws_instance.workers.*.public_ip, count.index)}"
  groups             = ["k8s_workers"]

  vars {
    ansible_user                  = "${var.admin_user}"
    ansible_ssh_private_key_file  = "/home/mbenabda/.ssh/wed_mbenabda_rsa"
    host_key_checking             = false
    k8s_api_public_hostname_or_ip = "${aws_eip.k8s_api.public_ip}"
  }
}

resource "ansible_host" "me" {
  inventory_hostname = "127.0.0.1"

  vars {
    k8s_api_public_hostname_or_ip = "${aws_eip.k8s_api.public_ip}"
  }
}
