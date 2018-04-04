resource "aws_vpc" "main" {
  cidr_block = "10.69.0.0/16"

  tags {
    Name = "vpc.mbenabda.k8s-1.9-the-hard-way"
  }
}
