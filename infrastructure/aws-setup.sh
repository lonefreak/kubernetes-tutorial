#! /bin/bash

source ./aws-utils.sh

export IMAGE_ID="ami-746aba14"

function createLoadBalancer() {
    local SUBNET_ID=$1
    local SECURITY_GROUP_ID=$2
    aws elb create-load-balancer \
        --load-balancer-name kubernetes \
        --listeners "Protocol=TCP,LoadBalancerPort=6443,InstanceProtocol=TCP,InstancePort=6443" \
        --subnets ${SUBNET_ID} \
        --security-groups ${SECURITY_GROUP_ID}
}

function createInstanceIAMPolicies() {
    aws iam create-role \
        --role-name kubernetes \
        --assume-role-policy-document file://files/kubernetes-iam-role.json

    aws iam put-role-policy \
        --role-name kubernetes \
        --policy-name kubernetes \
        --policy-document file://files/kubernetes-iam-policy.json
    if [ $? -eq 0 ]; then
        echo "IAM Role Policy kubernetes created."
    fi

    aws iam create-instance-profile \
        --instance-profile-name kubernetes 

    aws iam add-role-to-instance-profile \
        --instance-profile-name kubernetes \
        --role-name kubernetes
    if [ $? -eq 0 ]; then
        echo "IAM Role kubernetes added to Instance Profile kubernetes."
    fi
}

function createKubernetesMachine() {
    local NODE_TYPE=$1
    local NODE_INDEX=$2
    local SUBNET_ID=$3
    local SECURITY_GROUP_ID=$4
    
    if [ "${NODE_TYPE}" == "controller" ]; then IP_TERMINATION=1${NODE_INDEX}; fi
    if [ "${NODE_TYPE}" == "worker" ]; then IP_TERMINATION=2${NODE_INDEX}; fi
    local PRIVATE_IP_ADDRESS="10.240.0.${IP_TERMINATION}"
    local CONTROLLER_TAG="${NODE_TYPE}${MACHINE_INDEX}"
    
    echo "Creating instance ${CONTROLLER_TAG}"
    CONTROLLER_INSTANCE_ID=$(aws ec2 run-instances \
        --associate-public-ip-address \
        --iam-instance-profile 'Name=kubernetes' \
        --image-id ${IMAGE_ID} \
        --count 1 \
        --key-name kubernetes \
        --security-group-ids ${SECURITY_GROUP_ID} \
        --instance-type t2.small \
        --private-ip-address ${PRIVATE_IP_ADDRESS} \
        --subnet-id ${SUBNET_ID} | \
        jq -r '.Instances[].InstanceId')
    if [ "${CONTROLLER_INSTANCE_ID}" != "" ]; then
        echo "Instance ${CONTROLLER_INSTANCE_ID} created."
        sleep 5
        aws ec2 modify-instance-attribute \
            --instance-id ${CONTROLLER_INSTANCE_ID} \
            --no-source-dest-check
        aws ec2 create-tags \
            --resources ${CONTROLLER_INSTANCE_ID} \
            --tags Key=Name,Value=${CONTROLLER_TAG}
        else
            echo "Instance not created."
        fi
}

function createKubernetesControllers() {
    for i in `seq 0 2`; do
        createKubernetesMachine controller $i `getSubnetId` `getSecurityGroupId`
    done
}

function createKubernetesWorkers() {
    for i in `seq 0 2`; do
        createKubernetesMachine worker $i `getSubnetId` `getSecurityGroupId`
    done
}

function provisionVirtualMachines() {
    createInstanceIAMPolicies
    createKubernetesControllers
    createKubernetesWorkers
}

#Create ELB
createLoadBalancer `getSubnetId` `getSecurityGroupId`

#Provision Virtual Machines
provisionVirtualMachines

