# Transit VPC
# Information on GCP Regions and Zones https://cloud.google.com/compute/docs/regions-zones
# GCP zones b,c are almost universally available that's why we chose them



data "aviatrix_account" "account_id" {
  account_name = var.account
}



# Transit VPC
resource "aviatrix_vpc" "default" {
  cloud_type           = 4
  account_name         = var.account
  name                 = local.name
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = local.name
    cidr   = var.transit_cidr
    region = var.region
  }
}


# Management VPC
resource "aviatrix_vpc" "management_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-mgmt"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-mgmt"
    cidr   = local.mgmt_subnet_cidr
    region = var.region
  }
}

# LAN VPC 
resource "aviatrix_vpc" "lan_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-lan"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-lan"
    cidr   = local.lan_subnet_cidr
    region = var.region
  }
}

# Egress VPC
resource "aviatrix_vpc" "egress_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-egress"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  subnets {
    name   = "${local.name}-egress"
    cidr   = local.egress_subnet_cidr
    region = var.region
  }
}

# Aviatrix Transit GW
resource "aviatrix_transit_gateway" "default" {
  gw_name                          = local.name
  vpc_id                           = aviatrix_vpc.default.name
  cloud_type                       = 4
  vpc_reg                          = local.region1
  enable_active_mesh               = var.active_mesh
  gw_size                          = var.insane_mode ? var.insane_instance_size : var.instance_size
  account_name                     = var.account
  subnet                           = local.transit_subnet
  insane_mode                      = var.insane_mode
  ha_subnet                        = var.ha_gw ? local.transit_subnet : null
  ha_gw_size                       = var.ha_gw ? (var.insane_mode ? var.insane_instance_size : var.instance_size) : null
  ha_zone                          = var.ha_gw ? local.region2 : null
  connected_transit                = var.connected_transit
  bgp_manual_spoke_advertise_cidrs = var.bgp_manual_spoke_advertise_cidrs
  enable_learned_cidrs_approval    = var.learned_cidr_approval
  enable_transit_firenet            = var.transit_firenet
  enable_segmentation              = var.enable_segmentation
  single_az_ha                     = var.single_az_ha
  single_ip_snat                   = var.single_ip_snat
  lan_vpc_id                       = aviatrix_vpc.lan_vpc.name
  lan_private_subnet               = local.lan_subnet
  enable_advertise_transit_cidr    = var.enable_advertise_transit_cidr
  bgp_polling_time                 = var.bgp_polling_time
  bgp_ecmp                         = var.bgp_ecmp
}


# Firewall instances 
resource "aviatrix_firewall_instance" "firewall_instance" {
  count                  = var.ha_gw ? 0 : 1
  firewall_name          = "${local.name}-fw"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, data.aviatrix_account.account_id.gcloud_project_id)
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc.subnets[0].cidr, aviatrix_vpc.egress_vpc.subnets[0].region, aviatrix_vpc.egress_vpc.subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc.subnets[0].cidr, aviatrix_vpc.management_vpc.subnets[0].region, aviatrix_vpc.management_vpc.subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc.vpc_id : null
  egress_vpc_id =  aviatrix_vpc.egress_vpc.vpc_id
  bootstrap_bucket_name = var.bootstrap_bucket_name
  zone                   = local.region1
}



resource "aviatrix_firewall_instance" "firewall_instance_1" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw1"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, data.aviatrix_account.account_id.gcloud_project_id)
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc.subnets[0].cidr, aviatrix_vpc.egress_vpc.subnets[0].region, aviatrix_vpc.egress_vpc.subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc.subnets[0].cidr, aviatrix_vpc.management_vpc.subnets[0].region, aviatrix_vpc.management_vpc.subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc.vpc_id : null
  egress_vpc_id          = aviatrix_vpc.egress_vpc.vpc_id
  bootstrap_bucket_name  = var.bootstrap_bucket_name
  zone                   = var.ha_gw ? local.region1 : null
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw2"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, data.aviatrix_account.account_id.gcloud_project_id)
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version                
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc.subnets[0].cidr, aviatrix_vpc.egress_vpc.subnets[0].region, aviatrix_vpc.egress_vpc.subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc.subnets[0].cidr, aviatrix_vpc.management_vpc.subnets[0].region, aviatrix_vpc.management_vpc.subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc.vpc_id : null
  egress_vpc_id = aviatrix_vpc.egress_vpc.vpc_id
  bootstrap_bucket_name = var.bootstrap_bucket_name
  zone                   = var.ha_gw ? local.region2 : null
}

# Firenet
resource "aviatrix_firenet" "firenet" {
  vpc_id                               = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, data.aviatrix_account.account_id.gcloud_project_id)
  inspection_enabled                   = var.inspection_enabled
  egress_enabled                       = false
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.firenet_instance, aviatrix_firewall_instance_association.firenet_instance1, aviatrix_firewall_instance_association.firenet_instance2]
}


resource "aviatrix_firewall_instance_association" "firenet_instance" {
  count                = var.ha_gw ? 0 : 1
  vpc_id               = aviatrix_firewall_instance.firewall_instance[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance[0].egress_interface
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance1" {
  count                = var.ha_gw ? 1 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_1[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_1[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_1[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_1[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_1[0].egress_interface
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance2" {
  count                = var.ha_gw ? 1 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_2[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_2[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_2[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_2[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_2[0].egress_interface
  attached             = var.attached
}
