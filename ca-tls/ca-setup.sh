#! /bin/bash
# Depends on https://pkg.cfssl.org/
# How to install
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-certificate-authority.md

cfssl gencert -initca files/ca-csr.json | cfssljson -bare ca
if [ $? -eq 0 ]; then
    mv ca-key.pem ca.csr ca.pem certificates/
    openssl x509 -in certificates/ca.pem -text -noout
fi

