locals {

  shared_meta = merge(
    var.shared_meta,
    {
      REDIS_PASSWORD = random_password.postgres_redis["redis"].result
      POSTGRES_PASSWORD = random_password.postgres_redis["postgres"].result
    }
  )

  master_details = {
    master = merge(
      var.master,
      {
        metadata = merge(
          {
            NUM_SLAVES = length(var.parsehub_creds)
            GG_SHEET_URL = var.GG_SHEET_URL
            
            startup-script = file("${path.root}/startup_script/master.sh")
            ssh-keys = tls_private_key.ssh["master"].public_key_openssh
          },
          local.shared_meta
        )
      }
    )
  }

  slave_details = {
    for index, cred in var.parsehub_creds: 
      "slave${index+1}" => merge(
        var.slave,
        {
          metadata = merge(
            {
              startup-script = file("${path.root}/startup_script/slave.sh")
              ssh-keys = tls_private_key.ssh["slave"].public_key_openssh
            },
            local.shared_meta,
            cred
          )
        }
      )
  }

  VMs_details = merge(local.slave_details, local.master_details)
}
