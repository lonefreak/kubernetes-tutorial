#! /bin/bash

source ./aws-utils.sh

echo "SUBNET_ID=$(getSubnetId)"
echo "SECURITY_GROUP_ID=$(getSecurityGroupId)"
echo "LOAD_BALANCER_NAME=$(getLoadBalancerName)"
echo "Instances:"
aws ec2 describe-instances | \
#    --filters "Name=instance-state-name,Values=running" | \
    jq -j '.Reservations[].Instances[] | .InstanceId, "  ", .Placement.AvailabilityZone, "  ", .PrivateIpAddress, "  ", .PublicIpAddress, "  ", .State.Name, "\n"'
