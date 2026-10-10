terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_ec2_transit_gateway" "hybrid" {
  amazon_side_asn = "64512"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description = "TGW for Hybrid Cloud"
  tags        = { Name = "Main-TGW" }
}

resource "aws_customer_gateway" "vyos" {
  bgp_asn    = 65001
  ip_address = var.vyos_public_ip #
  type       = "ipsec.1"
  tags       = { Name = "VyOS-CGW" }
}

# 3. VPN Connection (TGW와 연결)
resource "aws_vpn_connection" "tgw_vpn" {
  customer_gateway_id = aws_customer_gateway.vyos.id
  transit_gateway_id  = aws_ec2_transit_gateway.hybrid.id
  type                = "ipsec.1"
  static_routes_only  = false # BGP 사용 권장

  tags = { Name = "VPN-to-TGW" }
}

# 4. VPC Attachment (VPC를 TGW에 연결)
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attach" {
  subnet_ids         = var.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.hybrid.id
  vpc_id             = var.vpc_id
  tags               = { Name = "TGW-VPC-Attachment" }
}

# 1. VPC 전송용 라우팅 테이블 (VPC가 연결됨)
resource "aws_ec2_transit_gateway_route_table" "vpc_tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hybrid.id
  tags               = { Name = "TGW-VPC-RT" }
}

# VPC를 이 테이블에 연결(Association)
resource "aws_ec2_transit_gateway_route_table_association" "vpc_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc_tgw_rt.id
}

# VPN의 경로를 이 테이블에 전파 (VPC가 VPN 대역을 알게 됨)
resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_vpc_prop" {
  transit_gateway_attachment_id  = aws_vpn_connection.tgw_vpn.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc_tgw_rt.id
}

# ---------------------------------------------------------

# 2. VPN 전송용 라우팅 테이블 (VPN이 연결됨)
resource "aws_ec2_transit_gateway_route_table" "vpn_tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hybrid.id
  tags               = { Name = "TGW-VPN-RT" }
}

# VPN을 이 테이블에 연결(Association)
resource "aws_ec2_transit_gateway_route_table_association" "vpn_assoc" {
  transit_gateway_attachment_id  = aws_vpn_connection.tgw_vpn.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn_tgw_rt.id
}

# VPC의 경로를 이 테이블에 전파 (VPN이 VPC 대역을 알게 됨)
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc_to_vpn_prop" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn_tgw_rt.id
}


resource "local_file" "vyos_vars" {
  filename = "${path.module}/ansible/vars/vpn_vars.yml"
  content  = <<EOT
local_public_ip: ""
local_private_ip: "192.168.0.254"
local_as: 65001
aws_as: 64512
openstack_network_cidr: "192.168.200.0/24"
openstack_network_cidr2: "172.30.1.0/24"
openstack_network_cidr3: "10.42.0.0/16""

# 앤서블이 찾고 있는 'tunnel1_vyos_inside_ip' 이름으로 구워줍니다.
tunnel1_psk: "${aws_vpn_connection.tgw_vpn.tunnel1_preshared_key}"
tunnel1_remote_ip: "${aws_vpn_connection.tgw_vpn.tunnel1_address}"
tunnel1_vyos_inside_ip: "${split("/", aws_vpn_connection.tgw_vpn.tunnel1_cgw_inside_address)[0]}"
tunnel1_aws_neighbor_ip: "${aws_vpn_connection.tgw_vpn.tunnel1_vgw_inside_address}"

tunnel2_psk: "${aws_vpn_connection.tgw_vpn.tunnel2_preshared_key}"
tunnel2_remote_ip: "${aws_vpn_connection.tgw_vpn.tunnel2_address}"
tunnel2_vyos_inside_ip: "${split("/", aws_vpn_connection.tgw_vpn.tunnel2_cgw_inside_address)[0]}"
tunnel2_aws_neighbor_ip: "${aws_vpn_connection.tgw_vpn.tunnel2_vgw_inside_address}"
EOT

  provisioner "local-exec" {
    command = "/root/ansible-setup/venv/bin/ansible-playbook -i hosts vpn_setup.yml"
    working_dir = "${path.module}/ansible"
  }
}






















