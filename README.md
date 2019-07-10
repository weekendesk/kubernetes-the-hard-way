# Introduction

This repository is intended for demo-ing the manual install of kubernetes's components on both master and worker nodes.

It should be able to get you to a working single master (insecure) kubernetes setup on a set of VMs

![End goal diagram](http://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/weekendesk/kubernetes-the-hard-way/VTWO-14496/end_goal.plantuml)


# prerequisites
- vagrant
- ansible
- cfssl
- cfssljson
- pip install netaddr

You can run the following command to check if you've missed something (don't worry, it won't install anything on your machine)
```sh
ansible-playbook kthw-playbook.yml -t check_prerequisites -l localhost
```


# Root Certificate Authority
Etcd and the Kubernetes components implement a certificates based authentication mecanism
We need certificates to :
  * enable authentication to the kubernetes api server.
  * enable authentication to the etcd cluster.

To create these certificates, we'll need a root Certificate Authority, that can be self signed by running !
```sh
ansible-playbook kthw-playbook.yml -t generate_the_root_ca -l localhost
```

# Infrastructure
- provision the vms the kubernetes cluster will be running on:
```sh
vagrant up
```

# Etcd cluster

```sh
ansible-playbook kthw-playbook.yml -t generate_etcd_cluster_auth_certificates
ansible-playbook kthw-playbook.yml -t distribute_etcd_cluster_auth_certificates -l etcd_peers
```

```sh
ansible-playbook kthw-playbook.yml -t generate_etcd_client_auth_certificates
ansible-playbook kthw-playbook.yml -t distribute_etcd_client_auth_certificates -l etcd_peers
```

```sh
ansible-playbook kthw-playbook.yml -t download_etcd -l etcd_peers
ansible-playbook kthw-playbook.yml -t start_etcd -l etcd_peers
```

### Verification

```sh
etcd_host=$(ansible-inventory --list | jq -r '.etcd_peers.hosts[0]')

ansible-playbook kthw-playbook.yml -t generate_etcd_test_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_etcd_test_client_certificate -l "$etcd_host"

vagrant ssh "$etcd_host"

ETCDCTL_API=2
etcdctl --ca-file=etcd_data-ca.pem --key-file=test-etcd_data-client-key.pem --cert-file=test-etcd_data-client.pem ls --recursive
etcdctl --ca-file=etcd_data-ca.pem --key-file=test-etcd_data-client-key.pem --cert-file=test-etcd_data-client.pem mk test value
etcdctl --ca-file=etcd_data-ca.pem --key-file=test-etcd_data-client-key.pem --cert-file=test-etcd_data-client.pem get test
etcdctl --ca-file=etcd_data-ca.pem --key-file=test-etcd_data-client-key.pem --cert-file=test-etcd_data-client.pem rm test
etcdctl --ca-file=etcd_data-ca.pem --key-file=test-etcd_data-client-key.pem --cert-file=test-etcd_data-client.pem ls --recursive
unset ETCDCTL_API
exit

unset etcd_host
ansible-playbook kthw-playbook.yml -t delete_etcd_test_client_certificate
```
### Resources
- [Bootstrapping the etcd Cluster](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md)

# Control Plane
## API Server
```sh
ansible-playbook kthw-playbook.yml -t generate_api_server_client_certificate_for_etcd_data
ansible-playbook kthw-playbook.yml -t distribute_api_server_client_certificate_for_etcd_data -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_api_server_certificate
ansible-playbook kthw-playbook.yml -t distribute_api_server_certificate -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_service_account_ca
ansible-playbook kthw-playbook.yml -t distribute_service_account_ca -l masters
```

```sh
encryption_key_for_secrets=$(head -c 32 /dev/urandom | base64)
ansible-playbook kthw-playbook.yml --extra-vars="secrets_encryption_key='$encryption_key_for_secrets'" -t configure_api_server_secrets_encryption -l masters 
```

```sh
ansible-playbook kthw-playbook.yml -t download_api_server -l masters
ansible-playbook kthw-playbook.yml -t start_api_server -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_the_admin_user
ansible-playbook kthw-playbook.yml -t configure_api_server_access_to_the_kubelets
```

### Verification

```sh
kubectl version --kubeconfig pki/admin_user/admin.kubeconfig
kubectl get clusterrole "system:kube-apiserver-to-kubelet" --kubeconfig pki/admin_user/admin.kubeconfig
kubectl get clusterrolebinding "system:kube-apiserver" --kubeconfig pki/admin_user/admin.kubeconfig
```

### Resources
- [Generating the Data Encryption Config and Key](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/06-data-encryption-keys.md)
- [Configure the Kubernetes API Server](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server)
- [The Service Account Key Pair](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-service-account-key-pair)
- [The Kubernetes API Server Certificate](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubernetes-api-server-certificate)
- [The Admin Client Certificate](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-admin-client-certificate)
- [The admin Kubernetes Configuration File](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-admin-kubernetes-configuration-file)
- [RBAC for Kubelet Authorization](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#rbac-for-kubelet-authorization)

## Controller Manager
```sh
ansible-playbook kthw-playbook.yml -t download_controller_manager -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_kube_controller_manager_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kube_controller_manager_client_certificate -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t start_controller_manager -l masters
```

### Resources
- [The Controller Manager Client Certificate](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-controller-manager-client-certificate)
- [The kube-controller-manager Kubernetes Configuration File](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-controller-manager-kubernetes-configuration-file)
- [Configure the Kubernetes Controller Manager](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager)


## Scheduler

```sh
ansible-playbook kthw-playbook.yml -t generate_kube_scheduler_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kube_scheduler_client_certificate -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t download_scheduler -l masters
ansible-playbook kthw-playbook.yml -t start_scheduler -l masters
```

### Resources
- [The Scheduler Client Certificate](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-scheduler-client-certificate)
- [The kube-scheduler Kubernetes Configuration File](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-scheduler-kubernetes-configuration-file)
- [Configure the Kubernetes Scheduler](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler)

# Worker nodes

## Kubelet
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l workers
```

```sh
ansible-playbook kthw-playbook.yml -t generate_kubelet_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kubelet_client_certificate -l workers 
```

```sh
ansible-playbook kthw-playbook.yml -t configure_kubelet_access_to_the_api_server
```

```sh
ansible-playbook kthw-playbook.yml -t setup_pod_networking -l workers 
```

```sh
ansible-playbook kthw-playbook.yml -t download_kubelet -l workers 
ansible-playbook kthw-playbook.yml -t start_kubelet -l workers 
```

### Verification

```sh
kubectl get nodes --kubeconfig pki/admin_user/admin.kubeconfig
```

### Resources
- [The Kubelet Client Certificates](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubelet-client-certificates)
- [The kubelet Kubernetes Configuration File](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kubelet-kubernetes-configuration-file)

## Kube-proxy
```sh
ansible-playbook kthw-playbook.yml -t generate_kube_proxy_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kube_proxy_client_certificate -l workers
```

```sh
ansible-playbook kthw-playbook.yml -t configure_kube_proxy_access_to_the_api_server -l workers
```

### Resources
- [The Kube Proxy Client Certificate](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kube-proxy-client-certificate)
- [The kube-proxy Kubernetes Configuration File](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-proxy-kubernetes-configuration-file)