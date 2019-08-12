#! /usr/bin/env bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# TODO: Pass by argument
# Get Broker LoadBalancer Address
BROKER_LB_IP=`kubectl get svc -n kafka kcluster-kafka-external-bootstrap --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`
echo $BROKER_LB_IP

BROKER_LB_PORT=`kubectl get svc -n kafka kcluster-kafka-external-bootstrap --output jsonpath='{.spec.ports[0].port}'`
echo $BROKER_LB_PORT

BROKER_EXTERNAL_ADDRESS="${BROKER_LB_IP}:${BROKER_LB_PORT}"
echo "${YELLOW}Kafka External Address: ${BROKER_EXTERNAL_ADDRESS}${NC}"

# Create kafka topic
UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="topic-${UUID}"
echo "${YELLOW}Test Topic: ${TESTING_TOPIC}${NC}"

# TODO: Deploy via CRD with kafka-topics.yaml
# Deploy via kafka broker pod - Alternatively this can be done through the CRD.
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic $TESTING_TOPIC --partitions 3 --replication-factor 2

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

# Produce messages through Kafkacat - connecting through external LoadBalancer IP
cat $MESSAGE_INPUT_FILE | kafkacat -P -b $BROKER_EXTERNAL_ADDRESS -t $TESTING_TOPIC

# Consume messages through Kafkacat - connecting through external LoadBalancer IP
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}-output-messages.txt"
kafkacat -C -b $BROKER_EXTERNAL_ADDRESS -t $TESTING_TOPIC > $MESSAGE_OUTPUT_FILE &

# TODO: verify this also kills the process on kafka client. We cannot remove the topic until the consumer is gone.
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID

echo "listing topics"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --list --zookeeper localhost:2181

# Delete test topic
echo "deleting test topic"
echo "kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic ${TESTING_TOPIC}"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC

echo "listing topics after deletion"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --list --zookeeper localhost:2181

# TODO: Compare what was produced and what was consumed.
# Compare contents of input and output
SORTED_INPUT="./temp/sorted-input.txt"
SORTED_OUTPUT="./temp/sorted-output.txt"
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