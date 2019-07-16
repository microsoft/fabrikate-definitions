# Fabrikate Portworx

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Portworx](https://github.com/portworx/helm).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "portworx"
    source: "https://github.com/microsoft/fabrikate-definitions.git"
    path: "definitions/fabrikate-portworx"
    method: "git"
```

### Setting Up Portworx

Extensive documentation exists at the [Helm Charts repo](https://github.com/portworx/helm/tree/master/charts/portworx#configuration). If you are running Portworx on AKS, it is recommended you change the PVC default storage class to managed premium for production workloads:

```yaml
portworx:
  persistence:
    storageClass: "managed-premium"
```

### Checking Portworx on your cluster

Portworx creates volumes inside your Kubernetes deployment that it issues as part of the Portworx ASG or cloud drive management. The same drives attach to the new instances automatically. For Azure Kubernetes Service deployments you can find the new disks inside your resource group with the handle `PX_DO_NOT_DELETE`. In the spec yaml used for Portworx, it defines the volumes/disk and nodes to be allocated to the cluster.

You can use the `pxctl` command Portworx provides to obtain metrics on how the volumes are being used: 
1. First get the name of a Portworx pod.

> `kubectl get pods -n=kube-system -l name=portworx`

2. Next grab the Portworx volume list which will give details on the provisioned volumes deployed. In this Kafka example we define the size and replica amount of the volumes in our statefulset yaml for Kafka and zookeeper.

> `kubectl exec <portowrx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl volume list`

3. Now grab the volume state details for a portworx disk. 

> `kubectl exec portworx-95vrn -n kube-system -- /opt/pwx/bin/pxctl volume inspect <volume_id>`
