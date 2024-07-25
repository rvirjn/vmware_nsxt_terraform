provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.nsx_username
  password              = var.nsx_password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
  api_timeout          = 10
}

#
# Here we show that you define a NSX tag which can be used later to easily to
# search for the created objects in NSX.
#
variable "nsx_tag_scope" {
  default = "project"
}

variable "nsx_tag" {
  default = "terraform-demo"
}


data "vsphere_datacenter" "datacenter" {
  name = "SDDC-Datacenter"
}

data "vsphere_distributed_virtual_switch" "sfo-m01-cl01-vds01" {
  name          = "sfo-m01-cl01-vds01"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
data "nsxt_policy_transport_zone" "overlay_transport_zone" {
  display_name = "nsx-overlay-transportzone"
}

resource "nsxt_policy_uplink_host_switch_profile" "WLD01-uplink-3129-aa" {
  description  = "Uplink host switch profile provisioned by Terraform"
  display_name = "WLD01-uplink-3129-aa"

  mtu            = 1500
  transport_vlan = 3129
  overlay_encap  = "GENEVE"
  teaming {
    active {
      uplink_name = "uplink1"
      uplink_type = "PNIC"
    }
    active {
      uplink_name = "uplink2"
      uplink_type = "PNIC"
    }
    policy = "FAILOVER_ORDER"
  }

  tag {
    scope = "color"
    tag   = "blue"
  }
}
resource "nsxt_policy_uplink_host_switch_profile" "WLD01-uplink-3130-aa" {
  description  = "Uplink host switch profile provisioned by Terraform"
  display_name = "WLD01-uplink-3130-aa"

  mtu            = 1500
  transport_vlan = 3130
  overlay_encap  = "GENEVE"
  teaming {
    active {
      uplink_name = "uplink1"
      uplink_type = "PNIC"
    }
    active {
      uplink_name = "uplink2"
      uplink_type = "PNIC"
    }
    policy = "LOADBALANCE_SRCID"
  }

  tag {
    scope = "color"
    tag   = "blue"
  }
}

resource "nsxt_policy_ip_pool" "WLD01-uplink-3129-aa" {
  display_name = "WLD01-uplink-3129-aa"
}

resource "nsxt_policy_ip_pool_static_subnet" "subnet-3129-aa" {
  display_name = "subnet-3129-aa"
  pool_path    = nsxt_policy_ip_pool.WLD01-uplink-3129-aa.path
  cidr         = "172.16.49.0/24"
  gateway      = "172.16.49.253"

  allocation_range {
    start = "172.16.49.51"
    end   = "172.16.49.80"
  }
}
resource "nsxt_policy_ip_pool" "WLD01-uplink-3130-aa" {
  display_name = "WLD01-uplink-3130-aa"
}

resource "nsxt_policy_ip_pool_static_subnet" "subnet-3130-aa" {
  display_name = "subnet-3130-aa"
  pool_path    = nsxt_policy_ip_pool.WLD01-uplink-3130-aa.path
  cidr         = "172.16.50.0/24"
  gateway      = "172.16.50.253"

  allocation_range {
    start = "172.16.50.51"
    end   = "172.16.50.80"
  }
}

resource "nsxt_failure_domain" "FD1" {
  display_name            = "FD1"
  description             = "FD1"
  preferred_edge_services = "active"
  tag {
    scope = "scope1"
    tag   = "tag1"
  }
}

resource "nsxt_failure_domain" "FD2" {
  display_name            = "FD2"
  description             = "FD2"
  preferred_edge_services = "active"
  tag {
    scope = "scope2"
    tag   = "tag2"
  }
}


resource "vsphere_distributed_port_group" "pg" {
  name                            = "pg1"
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.sfo-m01-cl01-vds01.id
  vlan_range {
    min_vlan = 100
    max_vlan = 199
  }
  vlan_range {
    min_vlan = 300
    max_vlan = 399
  }

}

