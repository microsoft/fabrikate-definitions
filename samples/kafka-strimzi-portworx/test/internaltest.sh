#! /usr/bin/env bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# TODO: Env vars for argument and configured values for the Kafka Cluster

# Deploy kafka client to use as producer and consumer. Topic and Users are required for the Client.
# Client also expects a secret for mirror-maker-cluster-ca-cert. Inserting a dummy string as the cert.
kubectl create secret generic -n kafka mirror-maker-cluster-ca-cert --from-literal=ca.crt=sample-faked-cert
kubectl apply -n kafka -f kafka-topics.yaml
kubectl apply -n kafka -f kafka-users.yaml
kubectl apply -n kafka -f kafka-client.yaml

# Create kafka topic
UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="topic-${UUID}"
echo "${YELLOW}Test Topic: ${TESTING_TOPIC}${NC}"

# Create testing directory
mkdir temp/${TESTING_TOPIC}

# TODO: Deploy via CRD with kafka-topics.yaml
# Deploy via kafka broker pod - Alternatively this can be done through the CRD.
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2

# Create random test messages
MESSAGE_INPUT_FILE="./temp/${TESTING_TOPIC}/input-messages.txt"

echo "Creating Input Message file."
for i in {0..9}
do
  MESSAGE=`uuidgen`
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE
done

cat $MESSAGE_INPUT_FILE

# Create messages via console producer
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC < $MESSAGE_INPUT_FILE

# Consume messages from topic
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}/output-messages.txt"
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > $MESSAGE_OUTPUT_FILE &

# TODO: verify this also kills the process on kafka client. We cannot remove the topic until the consumer is gone.
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

echo "listing topics"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --list --zookeeper localhost:2181

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
sort $MESSAGE_INPUT_FILE > $SORTED_INPUT
sort $MESSAGE_OUTPUT_FILE > $SORTED_OUTPUT

DIFF=`diff ${SORTED_INPUT} ${SORTED_OUTPUT}`
if [ "$DIFF" != "" ] 
then
    echo "${RED}Test Failed!!! - There's a difference between input and output!!!${NC}"
    exit 1
fi

echo "${GREEN}Test Passed!!! - All input messages are in the output!${NC}"
exit 0