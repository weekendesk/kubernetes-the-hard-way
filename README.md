# Introduction

This repository is intended for demo-ing the manual install of kubernetes's components on both master and worker nodes.

It should be able to get you to a working single master (insecure) kubernetes setup on a set of VMs

![End goal diagram](http://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/weekendesk/kubernetes-the-hard-way/VTWO-14496/end_goal.plantuml)


# prerequisites
- vagrant
- ansible
- cfssl
- cfssljson

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
ansible-playbook kthw-playbook.yml -t download_etcd -l etcd_peers
```

```sh
ansible-playbook kthw-playbook.yml -t generate_etcd_cluster_auth_certificates
ansible-playbook kthw-playbook.yml -t distribute_etcd_cluster_auth_certificates
```

```sh
ansible-playbook kthw-playbook.yml -t generate_etcd_client_auth_certificates
ansible-playbook kthw-playbook.yml -t distribute_etcd_client_auth_certificates
```

```sh
ansible-playbook kthw-playbook.yml -t start_etcd -l etcd_peers
```

# Kubernetes Control Plane
## API Server
```sh
ansible-playbook kthw-playbook.yml -t download_api_server -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_api_server_client_certificate_for_etcd_data
ansible-playbook kthw-playbook.yml -t distribute_api_server_client_certificate_for_etcd_data
```

```sh
ansible-playbook kthw-playbook.yml -t generate_api_server_certificate
ansible-playbook kthw-playbook.yml -t distribute_api_server_certificate -l masters
```

```sh
encryption_key_for_secrets=$(head -c 32 /dev/urandom | base64)
ansible-playbook kthw-playbook.yml --extra-vars="secrets_encryption_key='$encryption_key_for_secrets'" -t configure_api_server_secrets_encryption -l masters 
```

```sh
ansible-playbook kthw-playbook.yml -t start_api_server -l masters
```
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
## Scheduler
```sh
ansible-playbook kthw-playbook.yml -t download_scheduler -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t generate_kube_scheduler_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kube_scheduler_client_certificate -l masters
```

```sh
ansible-playbook kthw-playbook.yml -t start_scheduler -l masters
```

# Kubernetes worker nodes

## Kubelet
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l workers
ansible-playbook kthw-playbook.yml -t download_kubernetes_worker_components -l workers
```

```sh
ansible-playbook kthw-playbook.yml -t generate_kubelet_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kubelet_client_certificate -l workers 
```

```sh
ansible-playbook kthw-playbook.yml -t configure_kubelet_access_to_the_api_server -l workers 
```

## Kube-proxy
```sh
ansible-playbook kthw-playbook.yml -t generate_kube_proxy_client_certificate
ansible-playbook kthw-playbook.yml -t distribute_kube_proxy_client_certificate -l workers
```

```sh
ansible-playbook kthw-playbook.yml -t configure_kube_proxy_access_to_the_api_server -l workers
```

