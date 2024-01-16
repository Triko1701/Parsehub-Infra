output "ext_ip" {
    description = "VSI floating IP address"
    value = {
        for key, item in google_compute_address.main:
        key => item.address
    }
}
