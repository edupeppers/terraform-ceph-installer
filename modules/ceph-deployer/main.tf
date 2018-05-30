#------------------------------------------------------------------------------------
# Get a list of Availability Domains
#------------------------------------------------------------------------------------
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

#------------------------------------------------------------------------------------
# Get the OCID of the OS image to use
#------------------------------------------------------------------------------------
data "oci_core_images" "image_ocid" {
  compartment_id = "${var.compartment_ocid}"
  display_name = "${var.instance_os}"
}

#------------------------------------------------------------------------------------
# Create the Ceph Deployer Instance
#------------------------------------------------------------------------------------
resource "oci_core_instance" "instance" {
  availability_domain =  "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain_index - 1],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "${var.hostname}"
  hostname_label = "${var.hostname}"
  image = "${lookup(data.oci_core_images.image_ocid.images[0], "id")}"
  shape = "${var.shape}"
  subnet_id = "${var.subnet_id}"
  metadata {
    ssh_authorized_keys = "${file(var.ssh_public_key_file)}"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph.config"
    destination = "~/ceph.config"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/vm_setup.sh"
    destination = "~/vm_setup.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/add_to_known_hosts.sh"
    destination = "~/add_to_known_hosts.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/add_to_etc_hosts.sh"
    destination = "~/add_to_etc_hosts.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/install_ssh_key.sh"
    destination = "~/install_ssh_key.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/yum_repo_setup.sh"
    destination = "~/yum_repo_setup.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_yum_repo"
    destination = "~/ceph_yum_repo"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_firewall_setup.sh"
    destination = "~/ceph_firewall_setup.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/install_ceph_deploy.sh"
    destination = "~/install_ceph_deploy.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_new_cluster.sh"
    destination = "~/ceph_new_cluster.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_deploy_osd.sh"
    destination = "~/ceph_deploy_osd.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_deploy_mds.sh"
    destination = "~/ceph_deploy_mds.sh"
  }
  provisioner "file" {
    source = "${var.scripts_directory}/ceph_deploy_client.sh"
    destination = "~/ceph_deploy_client.sh"
  }
  connection {
    host = "${self.public_ip}"
    type = "ssh"
    user = "${var.ssh_username}"
    private_key = "${file(var.ssh_private_key_file)}"
  }
  timeouts {
    create = "${var.instance_create_timeout}"
  }
}

#------------------------------------------------------------------------------------
# Setup the VM
#------------------------------------------------------------------------------------
resource "null_resource" "vm_setup" {
  depends_on = ["oci_core_instance.instance"]
  provisioner "remote-exec" {
    connection {
      agent = false
      timeout = "30m"
      host = "${oci_core_instance.instance.public_ip}"
      user = "${var.ssh_username}"
      private_key = "${file(var.ssh_private_key_file)}"
    }
    inline = [
      "chmod +x ~/vm_setup.sh",
      "chmod +x ~/add_to_etc_hosts.sh",
      "chmod +x ~/add_to_known_hosts.sh",
      "chmod +x ~/install_ssh_key.sh",
      "chmod +x ~/yum_repo_setup.sh",
      "chmod +x ~/ceph_firewall_setup.sh",
      "chmod +x ~/install_ceph_deploy.sh",
      "chmod +x ~/ceph_new_cluster.sh",
      "chmod +x ~/ceph_deploy_osd.sh",
      "chmod +x ~/ceph_deploy_mds.sh",
      "chmod +x ~/ceph_deploy_client.sh",
      "~/vm_setup.sh deployer"
    ]
  }
}

#------------------------------------------------------------------------------------
# Setup the Ceph Deployer Instance
#------------------------------------------------------------------------------------
resource "null_resource" "deploy" {
  depends_on = ["null_resource.vm_setup"]
  provisioner "remote-exec" {
    connection {
      agent = false
      timeout = "30m"
      host = "${oci_core_instance.instance.public_ip}"
      user = "${var.ssh_username}"
      private_key = "${file(var.ssh_private_key_file)}"
    }
    inline = [
      "rm -rf ~/.ssh/id_rsa",
      "ssh-keygen -t rsa -q -P '' -f ~/.ssh/id_rsa",
      "~/yum_repo_setup.sh",
      "~/ceph_firewall_setup.sh deployer",
      "~/install_ceph_deploy.sh"
    ]
  }
}
