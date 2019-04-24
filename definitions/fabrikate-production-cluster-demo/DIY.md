# Deploy it yourself

This documentation intends to show how you can set up your own cluster that demonstrates Bedrock, Fabrikate, and the Cloud Native Stack. This documentation is _not_ comprehensive, and will refer you
to existing documentation, where necessary.

Additionally, this documentation will demonstrate setting up and deploying a _simple_ cluster. In a production setting, you will want to deploy an intermediary

## Provision a git repository for your Fabrikate components

In order for the Flux component in your cluster to be able to pull and apply Kubernetes manifests, you must set up a git repository, and associate a generated keypair with it. Follow the instructions [here](https://github.com/Microsoft/bedrock/tree/master/cluster/common/flux) to do this.

## Clone and render the demo cluster manifests

Clone the [fabrikate-production-cluster-demo](https://github.com/Microsoft/fabrikate-production-cluster-demo) repository to your computer.

Using the `fabrikate` tool available [here](https://github.com/Microsoft/fabrikate/releases), run `fab install` in the root directory of the project:

```sh
/code/fabrikate-production-cluster-demo $ fab install
> INFO[12-04-2019 11:02:07] fab version 0.4.0
> INFO[12-04-2019 11:02:07] 💾  Loading component.yaml
> INFO[12-04-2019 11:02:07] 💾  Loading config/common.yaml
…
…
> INFO[12-04-2019 11:03:52] 🚁  adding helm repo 'incubator' at https://kubernetes-charts-incubator.storage.googleapis.com/ for component 'jaeger'
> INFO[12-04-2019 11:03:53] 🚁  updating helm chart's dependencies for component 'jaeger'
> INFO[12-04-2019 11:04:00] 👈  finished install for component: jaeger
> INFO[12-04-2019 11:04:00] 🙌  finished install
```

This will recursively fetch Fabrikate components for each of the components defined in the `component.yaml` into the `components` directory. From there, you must render the components to yaml:

```sh
/code/fabrikate-production-cluster-demo $ fab generate prod
> INFO[12-04-2019 11:29:40] fab version 0.4.0
> INFO[12-04-2019 11:29:40] 💾  Loading component.yaml
> INFO[12-04-2019 11:29:40] 💾  Loading config/common.yaml
> INFO[12-04-2019 11:29:40] 🚚  generating component 'production-demo' statically from path ./manifests
…
…
> INFO[12-04-2019 11:29:41] 💾  Writing generated/prod/cloud-native/jaeger/fabrikate-jaeger.yaml
> INFO[12-04-2019 11:29:41] 💾  Writing generated/prod/cloud-native/jaeger/jaeger.yaml
> INFO[12-04-2019 11:29:41] 🙌  finished generate
```

You've now generated Kubernetes manifests from Fabrikate components. The generated manifests will be written to the `generated` directory. These generated manifests must now be committed to the git repository [you've set up](#provision-a-git-repository-for-your-fabrikate-components):

```sh
/code $ git clone https://github.com/username/my-flux-gitops-repository.git
> Cloning into 'my-flux-gitops-repository'...
…
> Receiving objects: 100% (117/117), 33.66 KiB | 2.10 MiB/s, done.
> Resolving deltas: 100% (54/54), done.

/code $ cd my-flux-gitops-repository
/code $ cp -r ../fabrikate-production-cluster-demo/generated .
/code $ git add .
/code $ git commit -m "Adding manifests"
/code $ git push origin HEAD
```

The generated manifests will now be available in the flux enabled repository: https://github.com/username/my-flux-gitops-repository.git

## Provision a Kubernetes cluster using Bedrock

You must set up a cluster running [Flux](https://github.com/weaveworks/flux). Flux observes the git repository that [you've set up](#provision-a-git-repository-for-your-fabrikate-components), and applies changes made to this repository to your cluster, thereby reducing a user's manual usage of `kubectl`. Clusters created using our Bedrock infrastructure will have this component installed. Follow the instructions [here](https://github.com/Microsoft/bedrock/tree/master/cluster/azure) to setup a [simple AKS](https://github.com/Microsoft/bedrock/tree/master/cluster/environments/azure-simple) cluster with the git repository you've provisioned above.

## Enable TLS in your cluster

The Cloud Native stack deploys Istio, a service mesh, which can act as an Ingress Controller for inbound HTTP traffic. In many cases, simply deploying the Ingress Controller with basic HTTP routing is not enough - passwords and other high security items are transmitted in plaintext, and a [man-in-the-middle](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) attack could compromise your users or your application. Enabling Istio's Ingress Controller to use a TLS Certificate allows your traffic to be encrypted between a client and your cluster, preventing a man-in-the-middle attack.

[Istio documentation](https://istio.io/docs/tasks/traffic-management/secure-ingress/mount/) details how this can be set up using a self signed certificate, but the same instructions can be followed to bring your own signed certificate obtained from a Certificate Authority, such as [Letsencrypt](https://letsencrypt.org/). The instructions provided by Istio will mount a certificate in your Kubernetes Cluster as a secret read by the Ingress Gateway to serve TLS/HTTPS traffic.

If you'd like to host your TLS certificates within Azure Keyvault, you can use the [Keyvault Flexvolume project](https://github.com/Azure/kubernetes-keyvault-flexvol). Follow the instructions in the README to set up the Keyvault Flexvolume driver in your cluster. We've additionally provided Istio-specific instructions [here](https://github.com/Azure/kubernetes-keyvault-flexvol/blob/master/docs/istio-tls-certificate.md)

## Feedback

Please open an issue on this repository if you need clarification on any of the resources provided above.
