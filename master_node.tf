locals {
  ami_id  = "ami-70054309"
  masters = "3"
}

data "template_file" "master_names" {
  count = "${local.masters}"

  template = "master-${count.index + 1}.${var.suffix}"
}

resource "aws_instance" "master" {
  count         = "${length(data.template_file.master_names.*.rendered)}"
  ami           = "${local.ami_id}"
  instance_type = "t2.medium"

  vpc_security_group_ids      = ["${aws_security_group.internal_traffic.id}"]
  subnet_id                   = "${aws_subnet.cluster_instances.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.key_name}"

  user_data = "${data.template_cloudinit_config.master.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "40"
  }

  tags {
    Name = "${element(data.template_file.master_names.*.rendered, count.index)}"
  }
}

data "template_file" "enable_ip_forwarding_script" {
  template = "${file("${path.module}/files/enable_ip_forwarding.sh")}"
}

data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.enable_ip_forwarding_script.rendered}"
  }
}
