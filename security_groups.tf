locals {
  devs_cidr_block = "195.68.50.34/32"
}

resource "aws_security_group" "internal_traffic" {
  name        = "internal_traffic.${var.suffix}"
  description = "Allow traffic inside the k8s cluster"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "icmp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "internal_traffic.${var.suffix}"
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh.${var.suffix}"
  description = "Allow inbound ssh traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.devs_cidr_block}"]
  }

  tags {
    Name = "ssh.${var.suffix}"
  }
}

resource "aws_security_group" "devs" {
  name        = "devs.${var.suffix}"
  description = "Allows us to ping, access the api, etc ... from our office"
  vpc_id      = "${aws_vpc.main.id}"

  # ping
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "icmp"
    cidr_blocks = ["${local.devs_cidr_block}"]
  }

  # api access
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${local.devs_cidr_block}"]
  }
}
