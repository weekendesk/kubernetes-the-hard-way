resource "aws_vpc" "main" {
  cidr_block = "10.69.0.0/16"

  tags {
    Name = "vpc.${var.suffix}"
  }
}

resource "aws_subnet" "cluster_instances" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.69.1.0/24"

  tags {
    Name = "cluster_instances.${var.suffix}"
  }
}
