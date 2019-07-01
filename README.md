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
ansible-playbook kthw-playbook.yml -t check_prerequisites
```


# Root Certificate Authority
Etcd and the Kubernetes components implement a certificates based authentication mecanism
We need certificates to :
  * enable authentication to the kubernetes api server.
  * enable authentication to the etcd cluster.

To create these certificates, we'll need a root Certificate Authority, that can be self signed by running !
```sh
ansible-playbook kthw-playbook.yml -t generate_the_root_ca
```

# Infrastructure
- provision the vms the kubernetes cluster will be running on:
```sh
vagrant up
```

# Etcd cluster
- download etcd
```sh
ansible-playbook kthw-playbook.yml -t download_etcd -l etcd_peers
```

# Kubernetes Control Plane
- setup a CRI-compatible container runtime 
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l masters
```
- download kubelet, kube-proxy, apiserver, scheduler and native controllers on the master nodes
```sh
ansible-playbook kthw-playbook.yml -t download_kubernetes_control_plane -l masters
```
- generate and distribute the certs:
```sh
ansible-playbook kthw-playbook.yml -t generate_the_api_server_cert
ansible-playbook kthw-playbook.yml -t distribute_certificates -l masters 
```

# Kubernetes worker nodes
- setup a CRI-compatible container runtime 
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l workers
```
- download kubelet & kube-proxy on the worker nodes
```sh
ansible-playbook kthw-playbook.yml -t download_kubernetes_worker_components -l workers
```
- generate and distribute the certs:
```sh
ansible-playbook kthw-playbook.yml -t generate_the_kubelet_client_certs
ansible-playbook kthw-playbook.yml -t distribute_certificates -l workers 
```


