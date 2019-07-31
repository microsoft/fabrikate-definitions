# Using Virtualized Storage with Portworx

Portworx provides cloud native storage for applications running in the cloud, on-prem and in hybrid/multi-cloud environments.

PX-Store includes:
- Container-optimized volumes with elastic scaling for no application downtime
- High Availability across nodes/racks/AZs so you can failover in seconds
- Multi-writer shared volumes across multiple containers
- Storage-aware class-of-service (COS) and application aware I/O tuning

> Currently the helm chart for Portworx is missing support for embedded the Azure service principal environment secrets for the PX-store deployment. Until a fix is provided, use the manual method below to deploy Portworx to your cluster.

## Setting up Portworx **Unstable**

To configure your Portworx Virtualization layer with Strimzi, use the following steps:

```
# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""


# Usually you would Generate custom specs for your portworx config. By default, our spec uses Premium volume types, 150 GB, Auto Data and 
# Management network interfaces with Stork, GUI enabled. Until the portworx generator has been modified to support the appropriate secret types use the
# spec.yaml provided. To customize this config use the api URL to download a custom yaml [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

kubectl apply -f px-gen-spec.yaml


> If you run into issues with Portworx deployment, run a `curl -fsL https://install.portworx.com/px-wipe | bash` to remove Portworx from the cluster then attempt to reinstall again

# Create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka
kubectl create -f perftest/kafka-px-ha-sc.yaml

```

## How to interact with Portworx

Portworx creates volumes inside your Kubernetes deployment that it issues as part of the Portworx ASG or cloud drive management. The same drives attach to the new instances automatically. For AKS deployments you can find the new disks inside your resource group with the handle `PX_DO_NOT_DELETE`. In the spec yaml used for Portworx, it defines the volumes/disk and nodes to be allocated to the cluster.

You can use the `pxctl` command Portworx provides to obtain metrics on how the volumes are being used: 
1. First get the name of a Portworx pod.

> `kubectl get pods -n=kube-system -l name=portworx`

2. Next grab the Portworx volume list which will give details on the provisioned volumes deployed. In this Kafka example we define the size and replica amount of the volumes in our statefulset yaml for Kafka and zookeeper.

> `kubectl exec <portowrx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl volume list`

```
ID                      NAME                                            SIZE    HA      SHARED  ENCRYPTED       IO_PRIORITY     STATUS                    SNAP-ENABLED
1055831288650462238     pvc-49e634a1-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.4no
144040088767070054      pvc-62df858e-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.5no
1003379156323793182     pvc-6394d9b7-a3fc-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.6no
924341013124639820      pvc-653a7482-a3fc-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.6no
283085716488210125      pvc-b3afc5cf-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.5no
935420839169754560      pvc-c32f46f5-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.4no
nmrose@MININT-86O9IGE:/mnt/c/Users/naros/Desktop/Microsoft/fy20/portworx/azure-kafka-kubernetes$ kubectl exec portworx-95vrn -n kube-system -- /opt/p
```
3. Now grab the volume state details for a portworx disk. 

> kubectl exec <portworx_pod>-n kube-system -- /opt/pwx/bin/pxctl volume inspect <volume_id>

```
Volume  :  924341013124639820
        Name                     :  pvc-653a7482-a3fc-11e9-872e-82275ba87b13
        Group                    :  kafka_vg
        Size                     :  20 GiB
        Format                   :  ext4
        HA                       :  3
        IO Priority              :  LOW
        Creation time            :  Jul 11 16:59:15 UTC 2019
        Shared                   :  no
        Status                   :  up
        State                    :  Attached: 2e491f27-4345-44be-88ee-fe57ba273efd (10.240.0.6)
        Device Path              :  /dev/pxd/pxd924341013124639820
        Labels                   :  group=kafka_vg,io_priority=high,namespace=default,pvc=data-kafka-0,repl=3
        Reads                    :  49
        Bytes Read               :  425984
        Writes                   :  253363
        Writes MS                :  8695884
        Bytes Written            :  23229157376
        IOs in progress          :  0
        Bytes used               :  1.8 GiB
        Replica sets on nodes:
                Set 0
                  Node           : 10.240.0.4 (Pool 0)
                  Node           : 10.240.0.6 (Pool 0)
                  Node           : 10.240.0.5 (Pool 0)
        Replication Status       :  Up
        Volume consumers         :
                - Name           : kafka-0 (fc673cc0-a4df-11e9-be84-168b323f0e4a) (Pod)
                  Namespace      : default
                  Running on     : aks-nodepool1-13284751-1
                  Controlled by  : kafka (StatefulSet)
```
For details on how to snapshot volumes using stork check out - https://portworx.com/run-ha-kafka-azure-kubernetes-service/.