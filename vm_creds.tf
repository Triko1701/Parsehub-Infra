resource "tls_private_key" "ssh" {
  for_each = toset(["master", "slave"])
  algorithm = "RSA"
}

resource "local_file" "public_ssh_key" {
  for_each = tls_private_key.ssh
  content  = each.value.public_key_openssh
  filename = "${path.root}/ssh-keys/${each.key}_public.pub"
}

resource "local_file" "private_ssh_key" {
  for_each = tls_private_key.ssh
  content  = each.value.private_key_openssh
  filename = "${path.root}/ssh-keys/${each.key}_private"
}

resource "random_password" "postgres_redis" {
  for_each = toset(["postgres", "redis"])

  length           = 16
  min_numeric      = 2
  min_upper        = 2
  min_lower        = 2
  special          = false
  # min_special      = 2

}