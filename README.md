# Aviatrix Transit Firenet for GCP

### Description
In the default state, this module deploys 4 VPCs (Transit Firenet, Management, Egress and LAN), Aviatrix transit gateways (HA), and firewall instances. Optionally, it can deploy only Transit and/or add BGPoverLAN interfaces and VPCs. Existing BGP and Transit VPCs can be reused.

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | 0.12 - 1.0 | >=6.5 | >=0.2.20

**_Information on older releases can be found in respective release notes._*

### Diagram
<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-gcp-transit-firenet/blob/master/img/gcp_transit_firenet.png?raw=true">


### Usage Example

Examples shown below are specific to each vendor.

#### Palo Alto Networks
```
module "gcp_ha_transit_1" {
  source                  = "terraform-aviatrix-modules/gcp-transit-firenet/aviatrix"
  version                 = "1.0.0"
  account                 = "GCP"
  transit_cidr            = "10.0.0.0/24" 
  firewall_cidr           = "10.0.1.0/26"
  region                  = "europe-west1"
  firewall_image          = "Palo Alto Networks VM-Series Next-Generation Firewall BYOL"
  firewall_image_version  = "9.1.3"
}

```
#### Check Point
```
module "transit_firenet_1" {
  source                  = "terraform-aviatrix-modules/gcp-transit-firenet/aviatrix"
  version                 = "1.0.0"
  account                 = "GCP"
  transit_cidr            = "10.0.0.0/24" 
  firewall_cidr           = "10.0.1.0/26"
  region                  = "europe-west1"
  firewall_image          = "Check Point CloudGuard IaaS Firewall & Threat Prevention (Gateway only) (BYOL)"
  firewall_image_version  = "R80.40-294.688"
}
```


#### Fortinet
```
module "transit_firenet_1" {
  source                  = "terraform-aviatrix-modules/gcp-transit-firenet/aviatrix"
  version                 = "1.0.0"
  account                 = "GCP"
  transit_cidr            = "10.0.0.0/24" 
  firewall_cidr           = "10.0.1.0/26"
  region                  = "europe-west1"
  firewall_image          = "Fortinet FortiGate Next-Generation Firewall (BYOL)"
  firewall_image_version  = "6.4.5"
}
```

### Variables
The following variables are required:

key | value
--- | ---
region | GCP region to deploy the transit and firewall VPCs in
account | The GCP access account on the Aviatrix controller, under which the controller will deploy these VPCs
transit_cidr | The IP CIDR to be used to create the Transit VPC (CIDR size must be between 16 to 28   **Insane mode requires a minimum 24**)
firewall_cidr | The IP CIDR  be used to create the Managment, Egress and LAN VPC  (CIDR size must be between 16 to 26)
firewall_image | String for the firewall image to use
firewall_image_version | The firewall image version specific to the NGFW vendor image 

Firewall images
```
Palo Alto Networks VM-Series Next-Generation Firewall BYOL
Check Point CloudGuard IaaS Firewall & Threat Prevention (Gateway only) (BYOL)
FortiGate Next-Generation Firewall (BYOL)
```

Firewall image versions tested
```
Palo Alto Networks - 9.1.3
Check Point        - 80.40-294.688
Fortinet           - 6.4.5
```

The following variables are optional:

key | default | value
:--- | :--- | :---
instance_size | n1-standard-1 | Size of the transit gateway instances. **Insane mode requires a minimum n1-highcpu-4 instance size**
fw_instance_size | n1-standard-4 | Size of the firewall instances
attached | true | Attach firewall instances to Aviatrix Gateways
ha_gw | true | Set to false to deploy single Aviatrix gateway. When set to false, fw_amount is ignored and only a single NGFW instance is deployed.
insane_mode | false | Set to true to enable Aviatrix insane mode high-performance encryption
name | null | When this string is set, user defined name is applied to all infrastructure supporting n+1 sets within a same region or other customization
egress_enabled | false | Set to true to enable egress inspection on the firewall instances
inspection_enabled | true | Set to false to disable inspection on the firewall instances
connected_transit | true | Set to false to disable connected_transit
bgp_manual_spoke_advertise_cidrs | | Intended CIDR list to advertise via BGP. Example: "10.2.0.0/16,10.4.0.0/16"
learned_cidr_approval | false | Switch to true to enable learned CIDR approval
active_mesh | true | Set to false to disable active_mesh
prefix | true | Boolean to enable prefix name with avx-
suffix | true | Boolean to enable suffix name with -transit
enable_segmentation | false | Switch to true to enable transit segmentation
insane_instance_size | n1-highcpu-4 | Instance size used when insane mode is enabled.
enable_egress_transit_firenet | false | Switch to true to enable egress on the transit firenet.
single_az_ha | true | Set to false if Controller managed Gateway HA is desired
single_ip_snat | false | Enable single_ip mode Source NAT for this container
enable_advertise_transit_cidr  | false | Switch to enable/disable advertise transit VPC network CIDR for a VGW connection
bgp_polling_time  | 50 | BGP route polling time. Unit is in seconds
bgp_ecmp  | false | Enable Equal Cost Multi Path (ECMP) routing for the next hop
bootstrap_bucket_name | null | Storagename to get bootstrap files from (PANW only)
local_as_number | | Changes the Aviatrix Transit Gateway ASN number before you setup Aviatrix Transit Gateway connection configurations.
enable_bgp_over_lan | false | Enable BGp over LAN. Creates eth4 for integration with SDWAN for example
enable_egress_transit_firenet | false | Set to true to enable egress on transit gw
az1 | c | AZ Zone to be used for Transit GW + NGFW deployment.
az2 | b | AZ Zone to be used for HA Transit GW + HA NGFW deployment.
tunnel_detection_time | null | The IPsec tunnel down detection time for the Spoke Gateway in seconds. Must be a number in the range [20-600]. Default is 60.
tags | null | Map of tags to assign to the gateway.
enable_multi_tier_transit |	false |	Switch to enable multi tier transit
egress_static_cidrs | [] | List of egress static CIDRs. Egress is required to be enabled. Example: ["1.171.15.184/32", "1.171.15.185/32"].
firewall_image_id | | Custom Firewall image ID.
learned_cidrs_approval_mode | | Learned cidrs approval mode. Defaults to Gateway. Valid values: gateway, connection
fail_close_enabled | | Set to true to enable fail close
east_west_inspection_excluded_cidrs | | Network List Excluded From East-West Inspection.
bgp_cidrs | | CIDRs for BGP over LAN VPCs. If the GW and HAGW need to be in separate VPCs, then specify both CIDRs like 10.0.0.0/28~10.0.0.16/28.
bgp_names | | Names of BGP over LAN VPCs. If the GW and HAGW need to be in separate VPCs, then specify both names like vpc-a~vpc-b. This list must correspond exactly with variable bgp_cidrs. This is required for using existing VPCs.
bgp_use_existing_vpcs | | Use existing VPCs for BGP over LAN?
transit_use_existing_vpcs | | Use existing VPC for Transit Gateway
bgp_asn | | BGP ASN for Transit Gateway
deploy_firenet | | Set to false to deploy Transit only.
transit_vpc_name | | Name of the Transit VPC. If not specified, the name will be generated automatically.

### Outputs
This module will return the following objects:

key | description
:--- | :---
[vpc](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_vpc) | The created VPC as an object with all of it's attributes. This was created using the aviatrix_vpc resource.
[transit_gateway](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_transit_gateway) | The created Aviatrix transit gateway as an object with all of it's attributes.
[aviatrix_firenet](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_firenet) | The created Aviatrix firenet object with all of it's attributes.
[aviatrix_firewall_instance](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_firewall_instance) | A list of the created firewall instances and their attributes.
