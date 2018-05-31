# どのプロバイダーを使用するのかを設定（今回はaws）
provider "aws" {
  access_key = "${var.access_key}" # var.hogeでhogeにアクセスできる
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# VPCを作る
resource "aws_vpc" "tf_tutorial_vpc" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "false"

  tags {
    Name = "vpc-1"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "tf_tutorial_gateway" {
  vpc_id = "${aws_vpc.tf_tutorial_vpc.id}" # tf_tutorial_vpcのidを参照
}

# サブネット
resource "aws_subnet" "public-b" {
  vpc_id            = "${aws_vpc.tf_tutorial_vpc.id}"
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-1b"
}

# ルーティング？
resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.tf_tutorial_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.tf_tutorial_gateway.id}"
  }
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = "${aws_subnet.public-b.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}

# セキュリティグループ
resource "aws_security_group" "admin" {
  name        = "admin"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.tf_tutorial_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cm_test" {
  ami           = "${var.images["ap-northeast-1"]}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.keypair_name}"

  vpc_security_group_ids = [
    "${aws_security_group.admin.id}",
  ]

  subnet_id                   = "${aws_subnet.public-b.id}"
  associate_public_ip_address = "true"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "20"
  }

  ebs_block_device = {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = "100"
  }

  tags {
    Name = "cm-test"
  }
}
