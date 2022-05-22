data "openstack_images_image_v2" "this" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "this" {
  vcpus = var.vcpus
  ram   = var.ram
}

data "openstack_networking_secgroup_v2" "default" {
  name = "default"
}

resource "openstack_compute_keypair_v2" "this" {
  name       = "benchmark_keypair"
  public_key = file(var.public_key)

}

resource "openstack_networking_port_v2" "this" {
  count              = var.server_count
  name               = "ece-server${count.index}"
  network_id         = openstack_networking_network_v2.this.id
  dns_name           = "ece-server${count.index}"
  security_group_ids = [data.openstack_networking_secgroup_v2.default.id, openstack_networking_secgroup_v2.administration.id, openstack_networking_secgroup_v2.servers.id]
  admin_state_up     = "true"
  depends_on = [
    openstack_networking_subnet_v2.this
  ]
}

resource "openstack_compute_instance_v2" "this" {
  count = var.server_count
  name  = "ece-server${count.index}"


  flavor_id       = data.openstack_compute_flavor_v2.this.id
  key_pair        = openstack_compute_keypair_v2.this.name
  security_groups = ["default", openstack_networking_secgroup_v2.administration.name, openstack_networking_secgroup_v2.servers.name]


  block_device {
    boot_index            = 0
    delete_on_termination = true
    destination_type      = "volume"
    source_type           = "image"
    uuid                  = data.openstack_images_image_v2.this.id
    volume_size           = 30
  }

  block_device {
    boot_index            = -1
    delete_on_termination = true
    destination_type      = "local"
    source_type           = "blank"
    volume_size           = 60
    guest_format          = "xfs"

  }

  network {
    port = openstack_networking_port_v2.this[count.index].id
  }
  depends_on = [
    openstack_networking_port_v2.this
  ]
}


resource "openstack_compute_floatingip_v2" "this" {
  count = var.server_count
  pool  = var.openstack_external_network_name

}

resource "openstack_compute_floatingip_associate_v2" "this" {
  count       = var.server_count
  floating_ip = openstack_compute_floatingip_v2.this[count.index].address
  instance_id = openstack_compute_instance_v2.this[count.index].id
}



data "template_file" "this" {
  template   = file("ansible-install.sh")
  depends_on = [openstack_compute_floatingip_associate_v2.this]
  vars = {

    ece-server0 = openstack_compute_floatingip_v2.this.0.address
    ece-server1 = openstack_compute_floatingip_v2.this.1.address
    ece-server2 = openstack_compute_floatingip_v2.this.2.address

    # Keys to server
    key = var.private_key

    # Server Device Name
    device = var.device_name

    # User to login
    user = var.remote_user

    # Ece version to install
    ece-version = var.ece-version

    # Sleep timeout waiting for cloud provider instances
    sleep-timeout = var.sleep-timeout
  }
}
