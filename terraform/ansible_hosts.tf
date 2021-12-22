resource "local_file" "build_ansible_hosts_file" {
  filename = "../ansible/hosts"
  content = templatefile("templates/hosts",
    {
      elastic_host_private = local.elastic_host_private_address,
      elastic_host_keyfile = aws_key_pair.blue_key.key_name,
      jump_host_public     = local.jump_host_public_address,
      jump_host_keyfile    = aws_key_pair.admin_key.key_name,
      kali_host_private    = local.kali_host_private_address,
      kali_host_keyfile    = aws_key_pair.red_key.key_name,
    }
  )
  depends_on = [
    aws_instance.jump_host,
    aws_instance.elastic_host,
    aws_instance.kali_host,
  ]
}
