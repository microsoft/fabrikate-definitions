# Using a Virtualized Storage: Portworx

Portworx provides cloud native storage for applications running in the cloud, on-prem and in hybrid/multi-cloud environments.

Portworx includes:
- Container-optimized volumes with elastic scaling for no application downtime
- High Availability across nodes/racks/AZs so you can failover in seconds
- Multi-writer shared volumes across multiple containers
- Storage-aware class-of-service (COS) and application aware I/O tuning

> Currently the helm chart for Portworx is missing support for embedding the Azure service principal environment secrets for the PX-store deployment. Until a fix is provided, use the manual method below to deploy Portworx to your cluster.

## Setting up Portworx Manually

To configure your Portworx Virtualization layer with Strimzi, use the following steps or run the [`strimzi-px-install.sg`](strimzi-px-install.sh) script.:

```
# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""

```
Typically you would generate custom specs for your portworx config. By default, our spec uses Premium volume types, 150 GB, Auto Data and Management network interfaces with Stork, GUI enabled. Until the portworx generator has been modified to support the appropriate secret types mentioned above, use the `px-gen-spec.yaml` provided. To customize this config use the api URL to download a custom yaml [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

> `kubectl apply -f temp-px-deploy/px-gen-spec.yaml`

* If you run into issues with Portworx deployment, run a `curl -fsL https://install.portworx.com/px-wipe | bash` to remove Portworx from the cluster then attempt to reinstall again. (Typically takes 1-5 minutes)

For interoperability with Strimzi & Kafka, create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka.

> `kubectl create -f temp-px-deploy/kafka-px-ha-sc.yaml`

## How to interact with Portworx

Portworx creates volumes inside your Kubernetes deployment that it issues as part of the Portworx ASG or cloud drive management. The same drives attach to the new instances automatically. For AKS deployments you can find the new disks inside your resource group with the handle `PX_DO_NOT_DELETE`. In the spec yaml used for Portworx, it defines the volumes/disk and nodes to be allocated to the cluster.

You can use the `pxctl` command Portworx provides to obtain metrics on how the volumes are being used: 
1. First get the name of a Portworx pod.

> `kubectl get pods -n=kube-system -l name=portworx`

2. Now you are able to view the provisioned Portworx disks dedicated for each node. 

> `kubectl exec <portworx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl status`

```
Status: PX is operational
License: Trial (expires in 31 days)
Node ID: ce4d4aca-fb23-4ac0-ad36-16fa627f1460
        IP: 10.240.0.6 
        Local Storage Pool: 1 pool
        POOL    IO_PRIORITY     RAID_LEVEL      USABLE  USED    STATUS  ZONE    REGION
        0       LOW             raid0           147 GiB 9.8 GiB Online  0       westus2
        Local Storage Devices: 1 device
        Device  Path            Media Type              Size            Last-Scan
        0:1     /dev/sdc2       STORAGE_MEDIUM_MAGNETIC 147 GiB         05 Aug 19 19:02 UTC
        total                   -                       147 GiB
        Cache Devices:
        No cache devices
        Journal Device:
        1       /dev/sdc1       STORAGE_MEDIUM_MAGNETIC
        Metadata Device:
        1       /dev/sdd        STORAGE_MEDIUM_MAGNETIC
Cluster Summary
        Cluster ID: px-cluster-4148c550-39b2-4954-8a15-fa0cfe584dd8
        Cluster UUID: 0ee425cf-2131-4a84-b734-152274cd9481
        Scheduler: kubernetes
        Nodes: 3 node(s) with storage (3 online)
        IP              ID                                      SchedulerNodeName               StorageNode     Used    Capacity        Status  StorageStatus   Version         Kernel                  OS
        10.240.0.6      ce4d4aca-fb23-4ac0-ad36-16fa627f1460    aks-nodepool1-40021484-0        Yes             9.8 GiB 147 GiB         Online  Up (This node)  2.1.1.0-6de97a6 4.15.0-1050-azure       Ubuntu 16.04.6 LTS
        10.240.0.5      1628bbf7-8780-4d52-9a5b-879f0da3fb14    aks-nodepool1-40021484-1        Yes             9.8 GiB 147 GiB         Online  Up              2.1.1.0-6de97a6 4.15.0-1050-azure       Ubuntu 16.04.6 LTS
        10.240.0.4      001c6978-7ec9-4c79-b5ca-224c3263738a    aks-nodepool1-40021484-2        Yes             9.8 GiB 147 GiB         Online  Up              2.1.1.0-6de97a6 4.15.0-1050-azure       Ubuntu 16.04.6 LTS
Global Storage Pool
        Total Used      :  29 GiB
        Total Capacity  :  441 GiB
```

3. **Once your storage class definition is applied and you provision PVCs from your application such as Strimzi**, next grab the Portworx volume list which will give details on the provisioned volumes deployed. In this Kafka example we define the size and replica amount of the volumes in our statefulset yaml for Kafka and zookeeper.

> `kubectl exec <portowrx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl volume list`

```
ID                      NAME                                            SIZE    HA      SHARED  ENCRYPTED       IO_PRIORITY     STATUS                    SNAP-ENABLED
1055831288650462238     pvc-49e634a1-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.4no
144040088767070054      pvc-62df858e-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.5no
1003379156323793182     pvc-6394d9b7-a3fc-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.6no
924341013124639820      pvc-653a7482-a3fc-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.6no
283085716488210125      pvc-b3afc5cf-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.5no
935420839169754560      pvc-c32f46f5-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.4no

```
4. Now grab the volume state details for a portworx disk. 

> `kubectl exec <portworx_pod>-n kube-system -- /opt/pwx/bin/pxctl volume inspect <volume_id>`

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

## Monitoring Portworx

In the provided Portworx spec file, `px-gen-spec.yaml`, there is an added port opening configuration under the daemonset section allowing Prometheus to scrape Portworx pods for metrics. In addition, added annotations for Prometheus to access the metric probes have been embedded for Prometheus integration. Navigate to prometheus and view the `px` metrics.

> Run `kubectl port-forward -n prometheus <prometheus_server_pod> 9090`

## High Availability & Snapshots with Portworx

High Availability and Disaster Recovery are built into Portworx out of the box. Here are some tips and 

### Portworx Failovers

You can simulate the failover for Portworx by cordoning off one of the nodes and deleting the Kafka Pod deployed on it. To start, follow the steps belor or run the [`px-failovertest.sh`](temp-px-perf/px-failovertest.sh). When the new pod is created it has the same data as the original Pod.

``` sh
$ NODE=`kubectl get pods -o wide -n kafka | grep px-cluster-kafka-0 | awk '{print $7}'`
$ kubectl cordon ${NODE}
```

Now Delete a pod.
> `kubectl delete -n kafka pod px-cluster-kafka-0`

Kubernetes controller now tries to create the Pod on a different node. Wait for the Kafka Pod to be in Running state on the node.

``` bash
$ kubectl get pods -n kafka  -o wide
NAME                                          READY   STATUS    RESTARTS   AGE    IP            NODE                       NOMINATED NODE
kafkaclient-0                                 1/1     Running   0          111m   10.244.1.5    aks-nodepool1-40021484-2   <none>
kafkaclient-1                                 1/1     Running   0          51m    10.244.2.10   aks-nodepool1-40021484-1   <none>
kafkaclient-2                                 1/1     Running   0          50m    10.244.0.13   aks-nodepool1-40021484-0   <none>
px-cluster-entity-operator-5787f8d64d-jnm2k   3/3     Running   0          51m    10.244.2.9    aks-nodepool1-40021484-1   <none>
px-cluster-kafka-0                            2/2     Running   0          52m    10.244.1.7    aks-nodepool1-40021484-1   <none>
px-cluster-kafka-1                            2/2     Running   0          52m    10.244.2.8    aks-nodepool1-40021484-1   <none>
px-cluster-kafka-2                            2/2     Running   0          52m    10.244.0.12   aks-nodepool1-40021484-0   <none>
px-cluster-zookeeper-0                        2/2     Running   0          53m    10.244.0.11   aks-nodepool1-40021484-0   <none>
px-cluster-zookeeper-1                        2/2     Running   0          53m    10.244.2.7    aks-nodepool1-40021484-1   <none>
px-cluster-zookeeper-2                        2/2     Running   0          53m    10.244.1.6    aks-nodepool1-40021484-2   <none>
strimzi-cluster-operator-68575878f6-th28x     1/1     Running   0          55m    10.244.2.6    aks-nodepool1-40021484-1   <none>  
```
Don’t forget to uncordon the node before proceeding further.
```
$ kubectl uncordon ${NODE}
node/aks-agentpool-23019497-2 uncordoned
```
Then verify that the messages are still available under the test topic

```
$ kubectl exec -it -n kafka kafkaclient-0 bash
# ./bin/kafka-console-consumer.sh --bootstrap-server px-cluster-kafka-brokers:9092 --topic test --partition 0 --from-beginning
message 1
message 2
message 3
Processed a total of 3 messages
```

### Backing up and restoring a Kafka node through snapshots

Portworx supports creating Snapshots for Kubernetes PVCs. When you install STORK, it also creates a storage class called stork-snapshot-sc. This storage class can be used to create PVCs from snapshots. To test portworx for backup scenarios run the [`px-snapshottest.sh`](temp-px-perf/px-snapshottest.sh).


For more details on how to snapshot volumes using stork check out [here](hhttps://docs.portworx.com/portworx-install-with-kubernetes/storage-operations/create-snapshots/snaps-annotations/#managing-snapshots-through-kubectl). 