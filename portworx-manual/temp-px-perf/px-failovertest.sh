#! /usr/bin/env bash

# Portworx Hgh Availability Fail Over Test

# Create kafka topic
UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

export TESTING_TOPIC="topic-${UUID}"
echo "Test Topic: ${TESTING_TOPIC}"



# Deploy via kafka broker pod - Alternatively this can be done through the CRD.
#kubectl exec -n kafka -ti px-cluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2
kubectl exec -n kafka -ti px-cluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2

 # Create random test messages
MESSAGE_INPUT_FILE="./temp/${TESTING_TOPIC}-input-messages.txt"

echo "Creating Input Message file."
for i in {0..9}
do
  MESSAGE=`uuidgen`
  # echo "Message: ${MESSAGE}"
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE

done
cat $MESSAGE_INPUT_FILE

# Create messages via console producer
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list px-cluster-kafka-brokers:9092 --topic $TESTING_TOPIC < $MESSAGE_INPUT_FILE

# Consume messages from topic
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}-output-messages.txt"
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server px-cluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE &

CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

# Test Portworx Failover

export NODE=`kubectl get pods -o wide -n kafka | grep px-cluster-kafka-0 | awk '{print $7}'`
kubectl cordon ${NODE}
echo "Cordoning Node:" ${NODE}
kubectl get nodes -o wide
sleep 2

echo
echo "Deleting kafka broker pod: px-cluster-kafka-0"
kubectl delete -n kafka pod px-cluster-kafka-0
sleep 2

echo
echo "Deleted kafka broker is now being created on new shared node"
kubectl get pods -n kafka  -o wide

# Check if messages from topic are still persisted on switched node.
MESSAGE_OUTPUT_FILE_CORDON="./temp/${TESTING_TOPIC}-cordon-output-messages.txt"
echo "Kafka broker messages after cordon are written at: " ${MESSAGE_OUTPUT_FILE_CORDON}
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server px-cluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE_CORDON &
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

# Uncordon the node
echo
echo "Uncordoning the node"
kubectl uncordon ${NODE}
