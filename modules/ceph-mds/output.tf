
output "ip_list" {
  value = "${oci_core_instance.instance.*.public_ip}"
}

output "hostname_list" {
  value = "${oci_core_instance.instance.*.hostname_label}"
}