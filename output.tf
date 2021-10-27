output "transit_vpc" {
  description = "The created Transit VPC with all of it's attributes"
  value       = aviatrix_vpc.default
}

output "egress_vpc" {
  description = "The created Egress VPC with all of it's attributes"
  value       = aviatrix_vpc.egress_vpc
}


output "management_vpc" {
  description = "The created Management VPC with all of it's attributes"
  value       = aviatrix_vpc.management_vpc
}


output "lan_vpc" {
  description = "The created LAN VPC with all of it's attributes"
  value       = aviatrix_vpc.lan_vpc
}

output "transit_gateway" {
  description = "The Aviatrix transit gateway object with all of it's attributes"
  value       = aviatrix_transit_gateway.default
}

output "aviatrix_firenet" {
  description = "The Aviatrix firenet object with all of it's attributes"
  value       = aviatrix_firenet.firenet
}

output "aviatrix_firewall_instance" {
  description = "A list with the created firewall instances and their attributes"
  value       = var.ha_gw ? [aviatrix_firewall_instance.firewall_instance_1[0], aviatrix_firewall_instance.firewall_instance_2[0]] : [aviatrix_firewall_instance.firewall_instance[0]]
}