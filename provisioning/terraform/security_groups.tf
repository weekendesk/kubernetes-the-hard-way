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
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "internal_traffic.${var.suffix}"
  }
}
