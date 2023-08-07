# Combining Istio with the Kubernetes Service Internal Traffic Policy

This repository contains the source code and configurations for an example that combines Istio with the K8s Service internal traffic policy to reduce external and internal network related costs and latency between inter-pod communication. 

![Alt text](./diagrams/diagram9.png?raw=true "Istio and the K8s Service Internal Traffic Policy")

## Why Use This Design Pattern?
Managing network traffic in Kubernetes is something that's both common and (sometimes) complex. For example, you might want to control the network flow for security reasons such as controlling which pods can talk to each other. Or you might want to manage the safe release of a new application version by splitting and controlling the amount of traffic directed to two versions of the same app. Other increasingly desired patterns are those associated with managing the cost and latency of network traffic in the cluster. 

Natively, Kubernetes has distinct features that support these use cases separately. Topology-aware routing is used to increase the likelihood of sending traffic coming from a certain availability zone to a destination in the same zone. By implication, this reduces the costs tied to egress cross-zone traffic. Then you have the service internal traffic policy which dictates the exclusive use of node-local endpoints so that inter-pod communication is restricted to the underlying node. But there's a constraint. At this point, these two features can't be used together. However, you can still adopt a pattern to address cost optimization and low latency requirements by combining Istio with the Kubernetes service internal traffic policy.

The way to combine Istio destination rules with the service internal traffic policy will largely depend on 3 things:
* The role of microservices
* Network traffic patterns
* How microservices should be deployed across the Kubernetes cluster topology

## Video
You can watch a detailed walk-through on this topic by viewing the video below. 

[![Alt text](./video-thumbnail.webp?raw=true "Video Thumbnail")](https://youtu.be/edSgEe7Rihc)

## Prerequisites
* [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)
* Kubernetes cluster
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [istioctl](https://istio.io/latest/docs/setup/getting-started/#download) 1.18.0
* Karpenter (not mandatory)

## Example Application
The example application has 3 microservices:
* GraphQL microservice - This service receives external traffic requests and plays the role of a data aggregator or an API gateway of sorts, and it talks to both orders and products.
<br />Endpoints:
``` /v1/graphql```

![Alt text](./diagrams/diagram2.png?raw=true "GraphQL API")

* Orders microservice - This service can be accessed through the GraphQL API or communicated with directly from an external source. There are two versions of orders, and both are fronted by the same Kubernetes service. They each return a different list of orders. In addition to that, orders 2 has an extra endpoint that communicates with products.
<br />Endpoints:
```
 - /v1/orders
 - /v1/orders/products (only supported in Orders 2 (version 0.3.7-alpha))
```

![Alt text](./diagrams/diagram3.png?raw=true "Orders API")

![Alt text](./diagrams/diagram4.png?raw=true "Orders versions with Kubernetes Service")

![Alt text](./diagrams/diagram5.png?raw=true "Responses from different Orders versions")

* Products microservice - This service doesn't send requests to any other API, it just serves internal requests from Orders and GraphQL. Like Orders, there are two different versions of Products that each return a different list of products.
<br />Endpoints:
```
 - /v1/products
```

![Alt text](./diagrams/diagram6.png?raw=true "Products API")

![Alt text](./diagrams/diagram7.png?raw=true "Products versions with Kubernetes Service")

![Alt text](./diagrams/diagram8.png?raw=true "Responses from different Products versions")

## Monitoring & Distributed Tracing
Observing network traffic patterns is very important when configuring controls to manage where and how traffic should flow across your cluster. 

In this exercise, Prometheus is used to monitor Istio components and services in the mesh, and Jaeger is used to trace network requests between the different services. For visualization of network traffic, you can either use Jaeger or Kiali. 

### Install Prometheus
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create ns prometheus
helm install prom prometheus-community/kube-prometheus-stack -n prometheus
```

After that, you can configure Prometheus to scrape/collect metrics from Istio using the custom resources in the *monitoring.yaml* file in the *observability* directory.

### Install Jaeger
Follow the steps [here](https://istio.io/latest/docs/ops/integrations/jaeger/#installation) to install Jaeger. 

### Install Kiali
```
kubectl create ns kiali-operator

helm install \
      --set cr.create=true \
      --set cr.namespace=istio-system \
      --namespace kiali-operator \
      --repo https://kiali.org/helm-charts \
      kiali-operator \
      kiali-operator

kubectl -n istio-system port-forward deploy/kiali 20001
```

Configure Kiali to connect to Prometheus and Jaeger by deploying the *kiali.yaml* file in the *observability* directory.

![Alt text](./diagrams/diagram1.png?raw=true "Kiali graph of network traffic")

## Node Autoscaling
To run the example application on dedicated nodes managed by Karpenter, create the Karpenter provisioner (*provisioner.yaml*) in the *karpenter* directory.

## Istio Resources
The resources to create a gateway, virtual services and destination rules for the example application can be found in the *istio-configs* directory. The Orders destination rule policy is used to manage zonal traffic destined for the Orders API.

## Kubernetes Configurations
The Kubernetes resources for the example application can be found in the *kubernetes-configs* directory. Once you've deployed the microservices, you can view where the pods are placed by running the script in the *scripts* directory. Make sure to update the script with the relevant node and zone information from your cluster.

After reviewing where pods are deployed across your cluster's topology, you can apply the Orders destination rule policy and configure the Products Kubernetes Service to `internalTrafficPolicy: Local`. 