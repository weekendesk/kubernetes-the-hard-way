# Provisioning a CA and Generating TLS Certificates

In this lab you will provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) using CloudFlare's PKI toolkit, [cfssl](https://github.com/cloudflare/cfssl), then use it to bootstrap a Certificate Authority, and generate TLS certificates for the following components: etcd, kube-apiserver, kubelet, and kube-proxy.

## Certificate Authority

In this section you will provision a Certificate Authority that can be used to generate additional TLS certificates.

Create the Certificate Authority configuration file and the Certificate Authority certificate signing request:


```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

Create the CA certificate signing request:

```
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes", 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",        
      "L": "Paris",
      "O": "Weekendesk",
      "OU": "Devops team",
      "ST": "île-de-France"
    }
  ]
} 
EOF
```

Generate the CA certificate and private key:

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

Results:

```
ca-key.pem
ca.pem
```

## Client and Server Certificates

In this section you will generate client and server certificates for each Kubernetes component and a client certificate for the Kubernetes `admin` user.

### The Admin Client Certificate

Create the `admin` client certificate signing request:

```
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",        
      "L": "Paris",
      "O": "system:masters",
      "OU": "Devops team",
      "ST": "île-de-France"
    }
  ]
}
EOF
```

Generate the `admin` client certificate and private key:

```
$ K8S_PUBLIC_IP=1.2.3.4 (the Elastic IP reserved in previous chapter)
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  -hostname K8S_PUBLIC_IP \
  admin-csr.json | cfssljson -bare admin
```

Results:

```
admin-key.pem
admin.pem
```

### The Kubelet Client Certificates

Kubernetes uses a [special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) called Node Authorizer, that specifically authorizes API requests made by [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the `system:nodes` group, with a username of `system:node:<nodeName>`. In this section you will create a certificate for each Kubernetes node that meets the Node Authorizer requirements.

Generate a certificate and private key for each Kubernetes node. In the following, replace:
* ${INTERNAL_IP} by the instance private IP
```
# do the following for each node:

$ node=node-1
$ INTERNAL_IP=1.2.3.4
cat > ${node}-csr.json <<EOF
{
  "CN": "system:node:${node}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Paris",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "île-de-France"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${node},${INTERNAL_IP} \
  -profile=kubernetes \
  ${node}-csr.json | cfssljson -bare ${node}
done
```

Results:

```
node-1-key.pem
node-1.pem
node-2-key.pem
node-3.pem
node-3-key.pem
node-3.pem
```

### The kube-proxy Client Certificate

Create the `kube-proxy` client certificate signing request:

```
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Paris",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "île-de-France"
    }
  ]
}
EOF
```

Generate the `kube-proxy` client certificate and private key:

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

Results:

```
kube-proxy-key.pem
kube-proxy.pem
```

### The Kubernetes API Server Certificate

The cluster public static IP address will be included in the list of subject alternative names for the Kubernetes API Server certificate. This will ensure the certificate can be validated by remote clients.

Create the Kubernetes API Server certificate signing request.

```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Paris",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Île-de-France"
    }
  ]
}
EOF
```

Generate the Kubernetes API Server certificate and private key. In the following, replace:
* ${K8S_PUBLIC_ADDRESS} by the cluster public IP
* ${MASTER_i_PRIV_IP} by the private ip of the master n°i

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
    -hostname=10.32.0.1,${MASTER_1_PRIV_IP},${MASTER_3_PRIV_IP},${MASTER_3_PRIV_IP},${K8S_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

Results:

```
kubernetes-key.pem
kubernetes.pem
```

## Distribute the Client and Server Certificates

Copy the appropriate certificates and private keys to each node instance. In the following, replace:
* ${node} by node-1, node-2 or node-3
* ${node-public-ip} by the public ip of the node
```
scp -i ~/.ssh/k8s-hard-way.pem ca.pem ${node}-key.pem ${node}.pem ubuntu@${node-public-ip}:~/
```

Copy the appropriate certificates and private keys to each master instance. In the following, replace:
* ${master-public-ip} by the public ip of the master
```
scp -i ~/.ssh/k8s-hard-way.pem ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem ubuntu@${master-public-ip}:~/
```

> The `kube-proxy` and `kubelet` client certificates will be used to generate client authentication configuration files in the next lab.

Next: [Generating Kubernetes Configuration Files for Authentication](05-kubernetes-configuration-files.md)
