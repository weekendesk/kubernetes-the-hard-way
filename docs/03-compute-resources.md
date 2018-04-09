# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the resources required for running a secure and highly available Kubernetes cluster (masters and nodes, behind a load-balancer) across a single region.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network

In this section a dedicated [Virtual Private Cloud](https://aws.amazon.com/vpc/) (VPC) and a [subnet](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html) will be setup to host the Kubernetes cluster.

Create the `k8s.the-hard-way` custom VPC:
* go in the VPC section of the AWS console
* click on the "Create VPC" button
* in the form that appeared, fill in the following informations:  
  Name tag: vpc.k8s-the-hard-way  
  IPv4 CIDR block: 10.69.0.0/16  
  IPv6 CIDR: "No IPv6 CIDR block"  
  block: leave that empty  
  Tenancy: default  

A [subnet](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html) must be provisioned with an IP address range large enough to assign a private IP address to each master and node in the Kubernetes cluster.

Create the `subnet.k8s-the-hard-way` subnet in the `vpc.k8s-the-hard-way` VPC network:
* go in the subnet section of the AWS console
* click on the "Create Subnet" button
* in the form that appeared, fill in the following informations:  
  Name tag: subnet.k8s-the-hard-way  
  VPC: vpc.k8s-the-hard-way  
  VPC CIDRS: will be filled automatically when choosing the VPC  
  Availability zone: No preference  
  IPv4 CIDR block: 10.69.1.0/24

> The `10.69.1.0/24` IP address range can host up to 254 compute instances.

### Firewall Rules

Using the AWS console, configure the security group to allow internal communication in the VPC across all protocols, allow incoming ssh and connexions on port 6443 (API) and all outgoing connexions (NTP, DNS resolution, softwares update):

* go in the security group section of the AWS console
* click on the default security group of the VPC
* change the description (from "default VPC security group" to "k8s allow internal traffic and incoming ssh/http")
* add a tag "Name" with the value "sg.k8s-the-hard-way"
* add the following rules:  
Inbound rules:  
  Type            | Protocol | Port range | Source  
  SSH             |   TCP    |    22      | Anywhere: 0.0.0.0/0   # to connect to the instance from your local workstation  
  Custom TCP rule |   TCP    |   6443     | Anywhere: 0.0.0.0/0   # access API from your local workstation  
  All ICMP - IPv4 |  ICMP    | 0 - 65535  | Anywhere: 0.0.0.0/0   
  All TCP         |   TCP    | 0 - 65535  | Custom: 10.69.0.0/16  
  All UDP         |   UDP    | 0 - 65535  | Custom: 10.69.0.0/16  
Outbound rules  
  Type          | Protocol | Port range | Source  
  All traffic     |   All    |    All     | Anywhere: 0.0.0.0/0   # NTP trafic, softwares updates, etc  

### Kubernetes Public IP Address

A few word about an instance having a public IP.
If an instance has a public IP (configuration parameter to enable in the instance configuration), the IP will be different if the machine reboots. If a machine has an Elastic IP, the IP will be the same after a reboot.

> An [external load balancer](https://aws.amazon.com/elasticloadbalancing/) will be created later to expose the Kubernetes API Servers to remote clients. You need to allocate a static IP address that will be attached to the load balancer fronting the Kubernetes API Servers: go to the Elastic IP panel and create a new Elastic IP (by choosing an elastic IP and not a public IP for the ELB, the IP will be static accross reboot, as seen previously). You do not need to assign this IP to anything at this moment, but the creation of the public IP is needed for the generation of SSL certificates, because you are going to use that IP address in the certificates.

During the installation process, kubernetes instances (masters and nodes) must have a public IP so you can execute commands on them using ssh. The default public IP that instance can have will be enough.

Now, an AWS VPC needs an Internet gateway to be internet-routable (meaning: go on the internet from the VPC instances, and join the instances from Internet). So you need to create an Internet gateway for your VPC. To enable access to or from the Internet for instances in a VPC, you must do the following:

* Attach an Internet gateway to your VPC:
  * Open the AWS VPC console, go to the Internet Gateways section. Click on the Create Internet Gateway button.
  * Choose the name "ig.k8s-the-hard-way" and then choose Yes, Create.
  * Select the Internet gateway that you just created, and then choose Attach to VPC.
  * In the Attach to VPC dialog box, select your VPC (vpc.kubernetes-the-hard-way) from the list, and then choose Yes, Attach.
* Ensure that your subnet's route table points to the Internet gateway:
  When the subnet `subnet.k8s-the-hard-way` was created it was automatically associated with the main route table for the VPC. By default, the main route table doesn't contain a route to an Internet gateway. So you need to edit this route table by adding a route that sends traffic destined outside the VPC to the Internet gateway, and then associates it with your subnet.
  * Open the AWS VPC console, go to the Route Tables section. Click on the default route table created with your VPC.
  * On the Routes tab, choose Edit, Add another route, and add the following routes as necessary (Destination 0.0.0.0/0, select the Internet gateway ID in the Target list). Choose Save when you're done.
  * On the Subnet Associations tab, choose Edit, select the Associate check box for the subnet, and then choose Save.

## Create Instances

The instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 16.04, which has good support for the [cri-containerd container runtime](https://github.com/containerd/cri-containerd). Each instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

### Kubernetes Masters

Create three compute instances which will host the Kubernetes control plane (change the name for each worker in the **tags** section):
* go in the instances section of the AWS console
* click on the "Launch instance" button
* on the AWS Marketplace, choose the AMI "Ubuntu 16.04 LTS - Xenial (HVM)"
* choose t2.medium as instance type
* on the "Configure Instance Details" page:  
  Network: vpc.k8s-the-hard-way  
  Subnet: subnet.k8s-the-hard-way  
  Auto-assign Public IP: Enable  
  IAM role: None  
  Shutdown behaviour: Stop  
  Enable termination protection: left uncheck  
  Monitoring: left unchecked  
  Tenancy: Shared
* on the "Add storage" page: configure a storage of size 200GB
* on the "Add Tags" page:  
    Key        | Value  
    Name       | k8s-master-{1,2,3} (change the number for each master)
* on the "Configure Security group" page:  
  tick "Select an existing security group" and choose the "sg.k8s-the-hard-way" security group
* choose the "k8s-the-hard-way" key pair

> Ask a collegue to give you this ssh private key and copy it in your `~/.ssh` directory. You can also choose to use a new key pair, in that case generate a new key pair.

Then, create a new Elastic IP, associate it to the newly created instance, ssh into the machine and enable ip forwarding.
```
$ ssh -i ~/.ssh/k8s-the-hard-way.pem ubuntu@public-ip-of-the-instance
ubuntu:~$ sudo -i
root:~# sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
root:~# sysctl -p /etc/sysctl.conf
```

### Kubernetes Nodes

Create three instances which will host the Kubernetes nodes (execute the following procedure three times):

* go in the instances section of the AWS console
* click on the "Launch instance" button
* on the AWS Marketplace, choose the AMI "Ubuntu 16.04 LTS - Xenial (HVM)"
* choose t2.medium as instance type
* on the "Configure Instance Details" page:  
  Network: vpc.k8s-the-hard-way  
  Subnet: subnet.k8s-the-hard-way  
  Auto-assign Public IP: Enable
  IAM role: None  
  Shutdown behaviour: Stop  
  Enable termination protection: left uncheck  
  Monitoring: left unchecked  
  Tenancy: Shared
* on the "Add storage" page: configure a storage of size 200GB
* on the "Add Tags" page:  
    Key      | Value  
    Name     | k8s-node-{1,2,3} (change the number for each node)
* on the "Configure Security group" page:  
  tick "Select an existing security group" and choose the "sg.k8s-the-hard-way" security group
* choose the "k8s-hard-way" key pair

Then, create a new Elastic IP, associate it to the newly created instance, ssh into the machine and enable ip forwarding.
```
$ ssh -i ~/.ssh/k8s-the-hard-way.pem ubuntu@public-ip-of-the-instance
ubuntu:~$ sudo -i
root:~# sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
root:~# sysctl -p /etc/sysctl.conf
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
