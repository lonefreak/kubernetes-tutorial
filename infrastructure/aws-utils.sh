function getLoadBalancerName() {
    echo $(aws elb describe-load-balancers --load-balancer-names kubernetes | jq -r .LoadBalancerDescriptions[0].LoadBalancerName)
}

function getSecurityGroupId() {
    echo $(aws ec2 describe-security-groups --filters Name=group-name,Values=kubernetes | jq -r .SecurityGroups[0].GroupId)
}

function getSubnetId() {
    echo $(aws ec2 describe-subnets --filters Name=tag-value,Values=kubernetes | jq -r .Subnets[0].SubnetId)
}
