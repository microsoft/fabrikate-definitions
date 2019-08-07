#! /usr/bin/env bash

# Portworx Snap Shot Single Cluster Back Up Test

# Create kafka topic

kubectl create -f kafka-snap.yaml

echo "Verifying volume snapshot creation"

kubectl get volumesnapshot

kubectl get volumesnapshotdatas # Not working

echo "Deleting kafka broker stateful set and PVC"

kubectl delete -n kafka sts/px-cluster-kafka
kubectl delete -n kafka pvc/data-px-cluster-kafka-0
kubectl delete -n kafka pvc/data-px-cluster-kafka-1
kubectl delete -n kafka pvc/data-px-cluster-kafka-2
kubectl get sts -n kafka
kubectl get po -n kafka
kubectl get pvc -n kafka

echo " Creating new PVC definition from the snapshot."

kubectl create -f kafka-snapshot-pvc.yaml
kubectl get pvc -n kafka

echo "Deploying new stateful set backend by the restored snapshot PVC will be automatically handled by the Strimzi Operator"

#kubectl apply -f kafka-px-ha-sc.yaml

echo "Checking pod successfully available and prior messages are persisted"

# Check if messages from topic are still persisted on switched node.
MESSAGE_OUTPUT_FILE_SNAPSHOT="./temp/${TESTING_TOPIC}-snapshot-output-messages.txt"
echo "Kafka broker messages after snapshot are written at: " ${MESSAGE_SNAPSHOT_FILE_CORDON}
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server px-cluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE_CORDON &
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID
echo