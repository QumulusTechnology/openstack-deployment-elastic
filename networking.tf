
data "openstack_networking_network_v2" "external" {
  name = var.openstack_external_network_name
}

resource "openstack_networking_network_v2" "this" {
  name           = "benchmark_net"
  admin_state_up = "true"
  mtu            = 1500
}

resource "openstack_networking_subnet_v2" "this" {
  name       = "benchmark_subnet"
  network_id = openstack_networking_network_v2.this.id
  cidr       = var.cidr
  ip_version = 4

}

resource "openstack_networking_router_v2" "this" {
  name                = "benchmark_router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "this" {
  router_id = openstack_networking_router_v2.this.id
  subnet_id = openstack_networking_subnet_v2.this.id
}

resource "openstack_networking_secgroup_v2" "administration" {
  name        = "administration"
  description = "administration security group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.trusted_network
  security_group_id = openstack_networking_secgroup_v2.administration.id
}

resource "openstack_networking_secgroup_rule_v2" "port12443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 12443
  port_range_max    = 12443
  remote_ip_prefix  = var.trusted_network
  security_group_id = openstack_networking_secgroup_v2.administration.id
}

resource "openstack_networking_secgroup_rule_v2" "port12343" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 12343
  port_range_max    = 12343
  remote_ip_prefix  = var.trusted_network
  security_group_id = openstack_networking_secgroup_v2.administration.id
}

resource "openstack_networking_secgroup_v2" "servers" {
  name        = "servers"
  description = "servers security group"
}

resource "openstack_networking_secgroup_rule_v2" "port9243" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9243
  port_range_max    = 9243
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.servers.id
}

resource "openstack_networking_secgroup_rule_v2" "port9343" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9343
  port_range_max    = 9343
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.servers.id
}
