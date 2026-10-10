output "vyos_hybrid_config_vars" {
  value = {
    # 1. 터널 공인 IP (VyOS의 remote-address)
    tunnel1_remote_ip = aws_vpn_connection.tgw_vpn.tunnel1_address
    tunnel2_remote_ip = aws_vpn_connection.tgw_vpn.tunnel2_address

    # 2. VTI 인터페이스용 내부 사설 IP (VyOS측)
    tunnel1_vyos_inside_ip = aws_vpn_connection.tgw_vpn.tunnel1_cgw_inside_address
    tunnel2_vyos_inside_ip = aws_vpn_connection.tgw_vpn.tunnel2_cgw_inside_address

    # 3. BGP Neighbor용 내부 사설 IP (AWS측)
    tunnel1_aws_neighbor_ip = aws_vpn_connection.tgw_vpn.tunnel1_vgw_inside_address
    tunnel2_aws_neighbor_ip = aws_vpn_connection.tgw_vpn.tunnel2_vgw_inside_address

    # 4. PSK (Pre-Shared Key)
    tunnel1_psk = aws_vpn_connection.tgw_vpn.tunnel1_preshared_key
    tunnel2_psk = aws_vpn_connection.tgw_vpn.tunnel2_preshared_key
  }
  sensitive = true # 중요 정보 포함으로 설정
}