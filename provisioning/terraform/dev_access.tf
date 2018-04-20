resource "aws_security_group" "ssh" {
  name        = "ssh.${var.suffix}"
  description = "Allow inbound ssh traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.wed_offices_cidrs}"
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
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.wed_offices_cidrs}"
  }

  # api access
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = "${var.wed_offices_cidrs}"
  }
}
