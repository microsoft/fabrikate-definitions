#! /usr/bin/env bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Portworx Hgh Availability Fail Over Test

# Deploy kafka client to use as producer and consumer. Topic and Users are required for the Client.
# Client also expects a secret for mirror-maker-cluster-ca-cert. Inserting a dummy string as the cert.
kubectl create secret generic -n kafka mirror-maker-cluster-ca-cert --from-literal=ca.crt=sample-faked-cert
kubectl apply -n kafka -f kafka-topics.yaml
kubectl apply -n kafka -f kafka-users.yaml
kubectl apply -n kafka -f kafka-client.yaml

# Create kafka topic
UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

export TESTING_TOPIC="topic-px-failover-${UUID}"
echo "Test Topic: ${TESTING_TOPIC}"

# Create testing directory
mkdir temp/${TESTING_TOPIC}

# Deploy via kafka broker pod - Alternatively this can be done through the CRD.
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2

 # Create random test messages
MESSAGE_INPUT_FILE="./temp/${TESTING_TOPIC}/input-messages.txt"

echo "Creating Input Message file."
for i in {0..9}
do
  MESSAGE=`uuidgen`
  # echo "Message: ${MESSAGE}"
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE

done
cat $MESSAGE_INPUT_FILE

# Create messages via console producer
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC < $MESSAGE_INPUT_FILE

# Consume messages from topic
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}/output-messages.txt"
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE &

CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

# Test Portworx Failover
# Cordon a node on the cluster
export NODE=`kubectl get pods -o wide -n kafka | grep kcluster-kafka-0 | awk '{print $7}'`
kubectl cordon ${NODE}
echo "Cordoning Node:" ${NODE}
kubectl get nodes -o wide
sleep 2
# Delete a kafka broker pod
echo
echo "Deleting kafka broker pod: kcluster-kafka-0"
kubectl delete -n kafka pod kcluster-kafka-0
sleep 2
echo
echo "Deleted kafka broker is now being created on new shared node"
kubectl get pods -n kafka  -o wide

# Check if messages from topic are still persisted on switched node.
MESSAGE_OUTPUT_FILE_CORDON="./temp/${TESTING_TOPIC}/cordon-output-messages.txt"
echo "Kafka broker messages after cordon are written at: " ${MESSAGE_OUTPUT_FILE_CORDON}
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE_CORDON &
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

# Uncordon the node
echo
echo "Uncordoning the node"
kubectl uncordon ${NODE}

# Remove client
kubectl delete -n kafka -f kafka-topics.yaml
kubectl delete -n kafka -f kafka-users.yaml
kubectl delete -n kafka -f kafka-client.yaml
kubectl delete secret -n kafka mirror-maker-cluster-ca-cert

# Waiting for kafka client to be deleted. This allows the test topic to be deleted.
sleep 60

# Delete test topic
echo "deleting test topic"
echo "kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic ${TESTING_TOPIC}"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC

echo "listing topics after deletion"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --list --zookeeper localhost:2181

# Compare contents of input and output
SORTED_INPUT="./temp/${TESTING_TOPIC}/sorted-input.txt"
SORTED_OUTPUT="./temp/${TESTING_TOPIC}/sorted-output.txt"
SORTED_CORDON_OUTPUT="./temp/${TESTING_TOPIC}/sorted-cordon-output.txt"
sort $MESSAGE_INPUT_FILE > $SORTED_INPUT
sort $MESSAGE_OUTPUT_FILE > $SORTED_OUTPUT
sort $MESSAGE_OUTPUT_FILE_CORDON > $SORTED_CORDON_OUTPUT

# Check if input and output match
DIFF=`diff ${SORTED_INPUT} ${SORTED_OUTPUT}`
if [ "$DIFF" != "" ] 
then
    echo "${RED}Test Failed!!! - There's a difference between input and output!!!${NC}"
    exit 1
fi
echo "${YELLOW}Check Passed!!! - All input messages are in the output!${NC}"

# Check if output and cordoned node output match
DIFF=`diff ${SORTED_OUTPUT} ${SORTED_CORDON_OUTPUT}`
if [ "$DIFF" != "" ] 
then
    echo "${RED}Test Failed!!! - There's a difference between the output and the corned node output!!!${NC}"
    exit 1
fi
echo "${GREEN}Test Passed!!! - All output messages are in the cordoned output!${NC}"
exit 0
