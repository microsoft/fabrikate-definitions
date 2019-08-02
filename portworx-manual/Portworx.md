# Using a Virtualized Storage: Portworx

Portworx provides cloud native storage for applications running in the cloud, on-prem and in hybrid/multi-cloud environments.

Portworx includes:
- Container-optimized volumes with elastic scaling for no application downtime
- High Availability across nodes/racks/AZs so you can failover in seconds
- Multi-writer shared volumes across multiple containers
- Storage-aware class-of-service (COS) and application aware I/O tuning

> Currently the helm chart for Portworx is missing support for embedding the Azure service principal environment secrets for the PX-store deployment. Until a fix is provided, use the manual method below to deploy Portworx to your cluster.

## Setting up Portworx Manually

To configure your Portworx Virtualization layer with Strimzi, use the following steps:

```
# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""

```
Normally you would generate custom specs for your portworx config. By default, our spec uses Premium volume types, 150 GB, Auto Data and Management network interfaces with Stork, GUI enabled. Until the portworx generator has been modified to support the appropriate secret types mentioned above, use the `px-gen-spec.yaml` provided. To customize this config use the api URL to download a custom yaml [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

Run `kubectl apply -f px-gen-spec.yaml`

> If you run into issues with Portworx deployment, run a `curl -fsL https://install.portworx.com/px-wipe | bash` to remove Portworx from the cluster then attempt to reinstall again

For interoperability with Strimzi & Kafka, create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka.

Run `kubectl create -f kafka-px-ha-sc.yaml`

## How to interact with Portworx

Portworx creates volumes inside your Kubernetes deployment that it issues as part of the Portworx ASG or cloud drive management. The same drives attach to the new instances automatically. For AKS deployments you can find the new disks inside your resource group with the handle `PX_DO_NOT_DELETE`. In the spec yaml used for Portworx, it defines the volumes/disk and nodes to be allocated to the cluster.

You can use the `pxctl` command Portworx provides to obtain metrics on how the volumes are being used: 
1. First get the name of a Portworx pod.

> `kubectl get pods -n=kube-system -l name=portworx`

Now you are able to view the provisioned Portworx disks dedicated for each node. 

2. Run `kubectl exec <portworx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl status`

```
       0:1     /dev/sdi        STORAGE_MEDIUM_MAGNETIC 150 GiB     
    31 Jul 19 15:32 UTC
        total                   -                       150 GiB
Cluster Summary
        Cluster ID: mycluster-00bede14-da12-4df8-88bf-5f73b3f2577e
        Cluster UUID: c4b28292-2237-4aed-af19-65f9f9b0e125
        Scheduler: kubernetes
        Nodes: 3 node(s) with storage (3 online)
        IP              ID                                      SchedulerNodeName       StorageNode     Used    Capacity        Status  StorageStatus   Version         Kernel                 OS        10.10.1.35      96ad0f14-5bd5-401b-a99e-b8080e135076    aks-default-37257775-0  Yes             9.6 GiB 150 GiB         Online  Up              2.1.2.0-21409c7 4.15.0-1050-azure      Ubuntu 16.04.6 LTS
        10.10.1.4       7d054b92-c66a-479a-bcd6-2460aac2364c    aks-default-37257775-2  Yes             9.6 GiB 150 GiB         Online  Up              2.1.2.0-21409c7 4.15.0-1050-azure      Ubuntu 16.04.6 LTS
        10.10.1.66      3b7e8f15-4eed-496b-9cd2-01e30a2393d7    aks-default-37257775-1  Yes             9.6 GiB 150 GiB         Online  Up (This node)  2.1.2.0-21409c7 4.15.0-1050-azure      Ubuntu 16.04.6 LTSGlobal Storage Pool
        Total Used      :  29 GiB
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
For details on how to snapshot volumes using stork check out - https://portworx.com/run-ha-kafka-azure-kubernetes-service/.

## Monitoring Portworx

In the provided Portworx spec file, `px-gen-spec.yaml`, there is an added port opening configuration under the daemonset section allowing Prometheus to scrape Portworx pods for metrics. In addition, added annotations for Prometheus to access the metric probes have been embedded for Prometheus integration. Navigate to prometheus and view the `px` metrics.

> Run `kubectl port-forward -n prometheus <prometheus_server_pod> 9090`

## High Availability & Snapshots with Portworx

High Availability and Disaster Recovery are built into Portworx out of the box. Here are some tips and 

### Portworx Failovers

You can simulate the failover for Portworx by cordoning off one of the nodes and deleting the Kafka Pod deployed on it. When the new Pod is created it has the same data as the original Pod.

``` sh
$ NODE=`kubectl get pods -o wide -n kafka | grep my-cluster-kafka-0 | awk '{print $7}'`
$ kubectl cordon ${NODE}
```

Kubernetes controller now tries to create the Pod on a different node. Wait for the Kafka Pod to be in Running state on the node.

```
kubectl get pods -l app=kafka -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP            NODE                       NOMINATED NODE
kafka-0   1/1     Running   0          1m    10.244.1.14   aks-agentpool-23019497-0   
```
Don’t forget to uncordon the node before proceeding further.
```
$ kubectl uncordon ${NODE}
node/aks-agentpool-23019497-2 uncordoned
```
Then verify that the messages are still available under the test topic

```
$ kubectl exec -it kafka-cli bash
# ./bin/kafka-console-consumer.sh --bootstrap-server kafka-broker:9092 --topic test --partition 0 --from-beginning
message 1
message 2
message 3
Processed a total of 3 messages
```

### Backing up and restoring a Kafka node through snapshots

Portworx supports creating Snapshots for Kubernetes PVCs. When you install STORK, it also creates a storage class called stork-snapshot-sc. This storage class can be used to create PVCs from snapshots.