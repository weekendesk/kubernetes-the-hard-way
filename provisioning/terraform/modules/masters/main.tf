data "template_file" "instance_names" {
  count = "${var.number_of_instances}"

  template = "master-${count.index + 1}.${var.suffix}"
}

resource "aws_instance" "instance" {
  count         = "${length(data.template_file.instance_names.*.rendered)}"
  ami           = "${var.ami}"
  instance_type = "t2.medium"

  vpc_security_group_ids      = ["${var.sg_ids}"]
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = true
  key_name                    = "${var.key_pair_name}"

  user_data = "${data.template_cloudinit_config.setup_instance.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "40"
  }

  tags {
    Name = "${element(data.template_file.instance_names.*.rendered, count.index)}"
  }
}

data "template_file" "enable_ip_forwarding_script" {
  template = "${file("${path.module}/files/enable_ip_forwarding.sh")}"
}

data "template_cloudinit_config" "setup_instance" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.enable_ip_forwarding_script.rendered}"
  }
}

output "instance_ids" {
  value = "${aws_instance.instance.*.id}"
}
