#! /usr/bin/env bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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

# Create testing directory
mkdir temp/${TESTING_TOPIC}

# Deploy test topic via Strimzi KafkaTopic CRD
echo "apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: ${TESTING_TOPIC}
  namespace: kafka
  labels:
    strimzi.io/cluster: kcluster
spec:
  partitions: 3
  replicas: 2
  config:
    retention.ms: 7200000
    segment.bytes: 1073741824" > temp/${TESTING_TOPIC}/kafka-test-topic.yaml

kubectl apply -f temp/${TESTING_TOPIC}/kafka-test-topic.yaml

sleep 2

# Deploy test user with access to test topic
echo "apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaUser
metadata:
  name: ${TESTING_TOPIC}-user
  namespace: kafka
  labels:
    strimzi.io/cluster: kcluster
spec:
  authentication:
    type: tls
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: ${TESTING_TOPIC}
          patternType: literal
        operation: All"  > temp/${TESTING_TOPIC}/kafka-test-user.yaml

kubectl apply -f temp/${TESTING_TOPIC}/kafka-test-user.yaml

sleep 2

# Get test user credentials
echo `kubectl get secrets $TESTING_TOPIC-user -o jsonpath="{.data['user\.crt']}"` | base64 --decode > temp/${TESTING_TOPIC}/user.crt
echo `kubectl get secrets $TESTING_TOPIC-user -o jsonpath="{.data['user\.key']}"` | base64 --decode > temp/${TESTING_TOPIC}/user.key

# Get kafka cluster CA cert
echo `kubectl get secrets kcluster-cluster-ca-cert -o jsonpath="{.data['ca\.crt']}"` | base64 --decode > temp/${TESTING_TOPIC}/ca.crt

# Create kafkacat.config file
echo "bootstrap.servers=${BROKER_EXTERNAL_ADDRESS}
security.protocol=ssl
ssl.key.location=temp/${TESTING_TOPIC}/user.key
ssl.certificate.location=temp/${TESTING_TOPIC}/user.crt
ssl.ca.location=temp/${TESTING_TOPIC}/ca.crt" > temp/${TESTING_TOPIC}/kafkacat.config

# Create random test messages
MESSAGE_INPUT_FILE="./temp/${TESTING_TOPIC}/input-messages.txt"

echo "Creating Input Message file."
for i in {0..9}
do
  MESSAGE=`uuidgen`
  echo "${MESSAGE}" >> $MESSAGE_INPUT_FILE
done

cat $MESSAGE_INPUT_FILE

# Produce messages through Kafkacat - connecting through external LoadBalancer IP
cat $MESSAGE_INPUT_FILE | kafkacat -P -F temp/${TESTING_TOPIC}/kafkacat.config -t $TESTING_TOPIC

# Consume messages through Kafkacat - connecting through external LoadBalancer IP
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}/output-messages.txt"
kafkacat -C -F temp/${TESTING_TOPIC}/kafkacat.config -t $TESTING_TOPIC > $MESSAGE_OUTPUT_FILE &

CONSUMER_PID=$!
sleep 5
kill $CONSUMER_PID

# Delete test topic and user
kubectl delete --recursive -f ./temp/${TESTING_TOPIC}

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