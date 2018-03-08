# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://docs.aws.amazon.com/fr_fr/AmazonVPC/latest/UserGuide/VPC_Route_Tables.html).

In this lab you will create a route for each node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `vpc.k8s-the-hard-way` VPC network.

For each node, retrieve its internal IP address and its Pod CIDR range. Example:
```
10.69.1.20 10.70.0.0/24
10.69.1.21 10.70.1.0/24
10.69.1.22 10.70.2.0/24
```

## Routes

Create network routes for each worker instance:

```
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

List the routes in the `kubernetes-the-hard-way` VPC network:

```
gcloud compute routes list --filter "network: kubernetes-the-hard-way"
```

> output

```
NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-236a40a8bc992b5b  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
default-route-df77b1e818a56b30  kubernetes-the-hard-way  10.240.0.0/24                            1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
