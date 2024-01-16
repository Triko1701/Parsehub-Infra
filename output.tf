output "ext_ip" {
    description = "VSI floating IP address"
    value = {
        for key, item in google_compute_address.main:
        key => item.address
    }
}


# output "test_path" {
#     value = local.a
# }

# locals {
#     a = file("${dirname(abspath(path.root))}\\gcp_project\\credentials.json")
# }