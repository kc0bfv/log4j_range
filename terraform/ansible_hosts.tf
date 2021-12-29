resource "local_file" "build_ansible_hosts_file" {
  filename = "../ansible/hosts"
  content = templatefile("templates/hosts",
    {
      solr_host_private       = local.solr_host_private_address,
      solr_host_keyfile       = aws_key_pair.blue_key.key_name,
      jump_host_public        = local.jump_host_public_address,
      jump_host_keyfile       = aws_key_pair.admin_key.key_name,
      kali_host_private       = local.kali_host_private_address,
      kali_host_keyfile       = aws_key_pair.red_key.key_name,
      freedns_ipv4_update_url = var.freedns_ipv4_update_url,
      freedns_ipv6_update_url = var.freedns_ipv6_update_url,
      freedns_domain_name     = var.freedns_domain_name,
      solr_host_vnc_password  = var.solr_host_vnc_password,
      kali_host_vnc_password  = var.kali_host_vnc_password,
      guac_admin_pass         = var.guac_admin_pass,
      guac_red_player_pass    = var.guac_red_player_pass,
    }
  )
  depends_on = [
    aws_instance.jump_host,
    aws_instance.solr_host,
    aws_instance.kali_host,
  ]
}
