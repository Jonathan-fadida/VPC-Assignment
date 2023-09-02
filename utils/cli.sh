#!/bin/bash

# Variables
vpc_cidr_block="10.0.0.0/16"
public_subnet_cidr_blocks=("10.0.1.0/24" "10.0.2.0/24")
private_subnet_cidr_blocks=("10.0.3.0/24" "10.0.4.0/24")

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --query 'Vpc.VpcId' --output text)

# Enable DNS resolution and hostname support for the VPC
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

# Create Public Subnets
for cidr_block in "${public_subnet_cidr_blocks[@]}"; do
    subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $cidr_block --query 'Subnet.SubnetId' --output text)
    
    # Create a public route table
    public_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
    
    # Add a route to the Internet Gateway for public subnets
    internet_gateway_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $internet_gateway_id
    aws ec2 create-route --route-table-id $public_route_table_id --destination-cidr-block "0.0.0.0/0" --gateway-id $internet_gateway_id
    
    # Associate the public route table with the public subnet
    aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $public_route_table_id
done

# Create Private Subnets
for cidr_block in "${private_subnet_cidr_blocks[@]}"; do
    subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $cidr_block --query 'Subnet.SubnetId' --output text)
    
    # Create a private route table
    private_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
    
    # Optionally, configure a NAT Gateway or NAT instance for private subnets to access the internet
    # Example:
    # nat_gateway_id=$(aws ec2 create-nat-gateway --subnet-id $subnet_id --allocation-id <your-eip-allocation-id> --query 'NatGateway.NatGatewayId' --output text)
    # aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block "0.0.0.0/0" --gateway-id $nat_gateway_id
    
    # Associate the private route table with the private subnet
    aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $private_route_table_id
done

# Output VPC and Subnet IDs
echo "VPC ID: $vpc_id"
