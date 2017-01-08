#! /bin/bash
# Depends on jq, aws-cli and envsubst

function clean() {
   rm certificates/* || true
   rm files/kubernetes-csr.json || true
}

trap "clean" EXIT 

KUBERNETES_PUBLIC_ADDRESS=$(aws elb describe-load-balancers \
                                --load-balancer-name kubernetes | \
                                jq -r '.LoadBalancerDescriptions[].DNSName')

envsubst < files/kubernetes-csr.json.tmpl > files/kubernetes-csr.json

cfssl gencert \
    -ca=certificates/ca.pem \
    -ca-key=certificates/ca-key.pem \
    -config=files/ca-config.json \
    -profile=kubernetes \
    files/kubernetes-csr.json | cfssljson -bare kubernetes
if [ $? -eq 0 ]; then
    mv kubernetes-key.pem kubernetes.csr kubernetes.pem certificates/
    openssl x509 -in certificates/kubernetes.pem -text -noout
else
    exit 1
fi

KUBERNETES_HOSTS=(controller0 controller1 controller2 worker0 worker1 worker2)

for host in ${KUBERNETES_HOSTS[*]}; do
    PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${host}" | \
        jq -r '.Reservations[].Instances[].PublicIpAddress')
    scp certificates/ca.pem certificates/kubernetes-key.pem certificates/kubernetes.pem \
        ubuntu@${PUBLIC_IP_ADDRESS}:~/
    if [ $? -eq 0 ]; then
        echo "Sent certificates to ${host} (${PUBLIC_IP_ADDRESS})"
    fi
done
