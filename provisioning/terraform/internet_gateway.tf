resource "aws_internet_gateway" "k8s_api" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "k8s_api.${var.suffix}"
  }
}

resource "aws_default_route_table" "cluster" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags {
    Name = "cluster.${var.suffix}"
  }
}

resource "aws_route_table_association" "cluster" {
  subnet_id      = "${aws_subnet.cluster_instances.id}"
  route_table_id = "${aws_default_route_table.cluster.id}"
}

resource "aws_route" "out" {
  route_table_id = "${aws_default_route_table.cluster.id}"
  gateway_id     = "${aws_internet_gateway.k8s_api.id}"

  destination_cidr_block = "0.0.0.0/0"
  depends_on             = ["aws_default_route_table.cluster"]
}

resource "aws_eip" "k8s_api" {
  vpc        = true
  instance   = "${element(module.masters.instance_ids, 0)}"
  depends_on = ["aws_internet_gateway.k8s_api"]

  tags {
    Name = "k8s_api.${var.suffix}"
  }
}
