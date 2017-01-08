#! /bin/bash

source ./aws-utils.sh

function deleteLoadBalancer() {
    local LOAD_BALANCER_NAME=$1
    aws elb delete-load-balancer --load-balancer-name ${LOAD_BALANCER_NAME}
    if [ $? -eq 0 ]; then
        echo "Load Balancer ${LOAD_BALANCER_NAME} deleted."
    fi
}

function deleteIAMRole() {
    local ROLE_NAME=$1
    aws iam delete-role --role-name ${ROLE_NAME}
    if [ $? -eq 0 ]; then
        echo "IAM Role ${ROLE_NAME} deleted."
    fi
}

function deleteIAMRolePolicy() {
    local ROLE_NAME=$1
    local POLICY_NAME=$1
    aws iam delete-role-policy --role-name ${ROLE_NAME} --policy-name ${POLICY_NAME}
    if [ $? -eq 0 ]; then
        echo "IAM Role Policy ${POLICY_NAME} deleted."
    fi
}

function deleteInstanceProfile() {
    local INSTANCE_PROFILE_NAME=$1
    aws iam delete-instance-profile --instance-profile-name ${INSTANCE_PROFILE_NAME}
    if [ $? -eq 0 ]; then
        echo "IAM Instance Profile ${INSTANCE_PROFILE_NAME} deleted."
    fi
}

function removeRoleFromInstanceProfile() {
    local INSTANCE_PROFILE_NAME=$1
    local ROLE_NAME=$1
    aws iam remove-role-from-instance-profile --instance-profile-name ${INSTANCE_PROFILE_NAME} --role-name ${ROLE_NAME}
    if [ $? -eq 0 ]; then
        echo "Role ${ROLE_NAME} removed from Instance Profile ${INSTANCE_PROFILE_NAME}."
    fi
}

function deleteIAMPolicies() {
    local TAG_NAME=$1
    removeRoleFromInstanceProfile ${TAG_NAME}
    deleteInstanceProfile ${TAG_NAME}
    deleteIAMRolePolicy ${TAG_NAME}
    deleteIAMRole ${TAG_NAME}
}

function deleteInstances() {
    local GROUP_NAME=$1
    local RUNNING_INSTANCES=`aws ec2 describe-instances --filters Name=instance-state-name,Values=running --filters Name=instance.group-name,Values=${GROUP_NAME} | jq -j '.Reservations[].Instances[] | .InstanceId, " "'`
    aws ec2 terminate-instances --instance-ids ${RUNNING_INSTANCES} 
    if [ $? -eq 0 ]; then
        echo "Instances ${RUNNING_INSTANCES} terminated."
    fi
}

# Delete running instance
deleteInstances kubernetes
# Delete IAM Policies
deleteIAMPolicies kubernetes
#Tear down ELB
deleteLoadBalancer `getLoadBalancerName`
