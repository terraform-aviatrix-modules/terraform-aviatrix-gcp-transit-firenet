variable "region" {
  description = "Primary GCP region where subnet and Aviatrix Transit Gateway will be created"
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
  description = "CIDR of the GCP transit subnet"
  type        = string
}

variable "firewall_cidr" {
  description = "CIDR to derive Firenet CIDR ranges"
  type        = string
  default     = ""
}

# variable "egress_subnet_cidr" {
#   description = "CIDR of the HA GCP subnet"
#   type        = string
#   default     = ""
# }

# variable "lan_subnet_cidr" {
#   description = "CIDR of the HA GCP subnet"
#   type        = string
#   default     = ""
# }

# variable "mgmt_subnet_cidr" {
#   description = "CIDR of the HA GCP subnet"
#   type        = string
#   default     = ""
# }

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
  description = "Name for this transit VPC and it's gateways"
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

variable "east_west_inspection_excluded_cidrs" {
  description = "Network List Excluded From East-West Inspection."
  type        = list(string)
  default     = null
}

variable "hpe" {
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
  description = "The firewall image to be used to deploy the NGFW's. If not specified, firewalls are not deployed"
  type        = string
  default     = ""

  validation {
    condition     = length(split("~", var.firewall_image)) == 2 || var.firewall_image == ""
    error_message = "The image must be specified as <firewall image name>~<version>. To disable Firenet, do not specify the variable."
  }
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

variable "bgp_cidrs" {
  description = "CIDRs for BGP over LAN VPCs. If the GW and HAGW need to be in separate VPCs, then specify both CIDRs like 10.0.0.0/28~10.0.0.16/28."
  type        = list(string)
  default     = null
}

variable "deploy_firenet" {
  description = "Set to false to fully deploy the Transit Firenet, but without the actual NGFW instances."
  type        = bool
  default     = true
}

locals {
  is_palo            = var.deploy_firenet ? length(regexall("palo", lower(var.firewall_image))) > 0 : null #Check if fw image contains palo. Needs special handling for management_subnet (CP & Fortigate null)
  lower_name         = length(var.name) > 0 ? replace(lower(var.name), " ", "-") : replace(lower(var.region), " ", "-")
  prefix             = var.prefix ? "avx-" : ""
  suffix             = var.suffix ? "-transit" : ""
  name               = "${local.prefix}${local.lower_name}${local.suffix}"
  cidrbits           = tonumber(split("/", var.transit_cidr)[1])
  newbits            = 26 - local.cidrbits
  netnum             = pow(2, local.newbits)
  lan_subnet_cidr    = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 4) : null
  egress_subnet_cidr = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 2) : null
  mgmt_subnet_cidr   = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 3) : null
  transit_subnet     = aviatrix_vpc.default.subnets[0].cidr
  # mgmt_subnet        = aviatrix_vpc.management_vpc[0].subnets[0].cidr
  # lan_subnet         = aviatrix_vpc.lan_vpc[0].subnets[0].cidr
  # egress_subnet      = aviatrix_vpc.egress_vpc[0].subnets[0].cidr
  region1                = "${var.region}-${var.az1}"
  region2                = "${var.region}-${var.az2}"
  hpe                    = var.hpe || var.bgp_cidrs != null ? true : false
  firewall_image         = var.deploy_firenet ? element(split("~", var.firewall_image), 0) : null
  firewall_image_version = var.deploy_firenet ? element(split("~", var.firewall_image), 1) : null
}
