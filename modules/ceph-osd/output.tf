
output "ip_list" {
  value = "${oci_core_instance.instances.*.private_ip}"
}

output "hostname_list" {
  value = "${oci_core_instance.instances.*.hostname_label}"
}

output "deploy" {
  value = "${null_resource.deploy.id}"
}
