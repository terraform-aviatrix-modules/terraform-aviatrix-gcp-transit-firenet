variable "region" {
  description = "Primary GCP region where subnet and Aviatrix Transit Gateway will be created"
  type        = string
}
variable "transit_firenet" {
 description = "Enable Transit Firenet"
  default     = true
  type        = string
}

variable "account" {
  description = "Name of the GCP Access Account defined in the Aviatrix Controller"
  type        = string
}

variable "instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-standard-1"
  type        = string
}


variable "insane_instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-highcpu-4"
  type        = string
}

variable "fw_instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-standard-4"
  type        = string
}

variable "transit_cidr" {
  description = "CIDR of the primary GCP subnet"
  type        = string
}

variable "firewall_cidr" {
  description = "CIDR of the HA GCP subnet"
  type        = string
  default     = ""
}

variable "egress_subnet_cidr" {
  description = "CIDR of the HA GCP subnet"
  type        = string
  default     = ""
}

variable "lan_subnet_cidr" {
  description = "CIDR of the HA GCP subnet"
  type        = string
  default     = ""
}

variable "mgmt_subnet_cidr" {
  description = "CIDR of the HA GCP subnet"
  type        = string
  default     = ""
}

variable "ha_gw" {
  description = "Set to false te deploy a single transit GW"
  type        = bool
  default     = true
}

variable "az1" {
  description = "Concatenates with region to form az names. e.g. us-east1b."
  type        = string
  default     = "b"
}

variable "az2" {
  description = "Concatenates with region or ha_region (depending whether ha_region is set) to form az names. e.g. us-east1c."
  type        = string
  default     = "c"
}

variable "name" {
  description = "Name for this spoke VPC and it's gateways"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Boolean to determine if name will be prepended with avx-"
  type        = bool
  default     = false
}

variable "suffix" {
  description = "Boolean to determine if name will be appended with -transit"
  type        = bool
  default     = false
}

variable "connected_transit" {
  description = "Set to false to disable connected transit."
  type        = bool
  default     = true
}

variable "bgp_manual_spoke_advertise_cidrs" {
  description = "Define a list of CIDRs that should be advertised via BGP."
  type        = string
  default     = ""
}

variable "learned_cidr_approval" {
  description = "Set to true to enable learned CIDR approval."
  type        = string
  default     = "false"
}

variable "active_mesh" {
  description = "Set to false to disable active mesh."
  type        = bool
  default     = true
}

variable "insane_mode" {
  description = "Boolean to enable insane mode"
  type        = bool
  default     = false
}

variable "enable_segmentation" {
  description = "Switch to true to enable transit segmentation"
  type        = bool
  default     = false
}

variable "single_az_ha" {
  description = "Set to true if Controller managed Gateway HA is desired"
  type        = bool
  default     = true
}

variable "single_ip_snat" {
  description = "Enable single_ip mode Source NAT for this container"
  type        = bool
  default     = false
}

variable "enable_advertise_transit_cidr" {
  description = "Switch to enable/disable advertise transit VPC network CIDR for a VGW connection"
  type        = bool
  default     = false
}

variable "bgp_polling_time" {
  description = "BGP route polling time. Unit is in seconds"
  type        = string
  default     = "50"
}

variable "bgp_ecmp" {
  description = "Enable Equal Cost Multi Path (ECMP) routing for the next hop"
  type        = bool
  default     = false
}


variable "firewall_image" {
  description = "The firewall image to be used to deploy the NGFW's"
  type        = string
}

variable "firewall_image_version" {
  description = "The firewall image version specific to the NGFW vendor image"
  type        = string
}


variable "egress_enabled" {
  description = "Set to true to enable egress inspection on the firewall instances"
  type        = bool
  default     = false
}

variable "inspection_enabled" {
  description = "Set to false to disable inspection on the firewall instances"
  type        = bool
  default     = true
}


variable "attached" {
  description = "Boolean to determine if the spawned firewall instances will be attached on creation"
  type        = bool
  default     = true
}

variable "bootstrap_bucket_name" {
  description = "The firewall bootstrap bucket name"
  type        = string
  default     = null
}


locals {
  is_palo       = length(regexall("palo", lower(var.firewall_image))) > 0  #Check if fw image contains palo. Needs special handling for management_subnet (CP & Fortigate null)
  lower_name = length(var.name) > 0 ? replace(lower(var.name), " ", "-") : replace(lower(var.region), " ", "-")
  prefix     = var.prefix ? "avx-" : ""
  suffix     = var.suffix ? "-transit" : ""
  name       = "${local.prefix}${local.lower_name}${local.suffix}"
  cidrbits                 = tonumber(split("/", var.transit_cidr)[1])
  newbits                  = 26 - local.cidrbits
  netnum                   = pow(2, local.newbits)
  lan_subnet_cidr     = cidrsubnet(var.firewall_cidr, local.newbits, local.netnum -4)
  egress_subnet_cidr     = cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 2)
  mgmt_subnet_cidr    = cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 3)
  transit_subnet  = aviatrix_vpc.default.subnets[0].cidr
  mgmt_subnet     =  aviatrix_vpc.management_vpc.subnets[0].cidr
  lan_subnet     = aviatrix_vpc.lan_vpc.subnets[0].cidr
  egress_subnet     =  aviatrix_vpc.egress_vpc.subnets[0].cidr
  region1    = "${var.region}-${var.az1}"
  region2    = "${var.region}-${var.az2}"
}
