#! /usr/bin/env bash

#### CONSTANTS --------------------------------
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

MTLS_ON=false
K_CONNECT_ON=false

#### ARGS AND INPUTS
while [ ! $# -eq 0 ]
do
	case "$1" in
		-t)
      echo "${CYAN}mTLS/SSL Support enabled.${NC}"
      MTLS_ON=true
			;;
		-k)
			echo "${CYAN}Kafka Connect test enabled.${NC}"
      K_CONNECT_ON=true
			;;
	esac
	shift
done

#### FUNCTIONS --------------------------------
create_and_deploy_kafka_test_topic_yaml()
{
    TESTING_TOPIC=$1
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
}

create_and_deploy_kafka_test_user_yaml()
{
    TESTING_TOPIC=$1
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
        operation: All" > temp/${TESTING_TOPIC}/kafka-test-user.yaml

    kubectl apply -f temp/${TESTING_TOPIC}/kafka-test-user.yaml

    sleep 2
}

cleanup_cluster()
{
    TESTING_TOPIC=$1
    kubectl delete --recursive -f ./temp/${TESTING_TOPIC}
}

deploy_kafka_connect_connector()
{
  # Get MongoDB Credentials from Env Vars.

  # Create connector payload
  CONNECTOR_FILE="./temp/${TESTING_TOPIC}/create-connector.json"
  cp ../examples/kafka_connect/connectors/mongoDBSink/CreateMongoSinkConnector.json $CONNECTOR_FILE
  
  # 2 "name"
  KCONNECT_NAME="${TESTING_TOPIC}-connector"
  echo "Kafka Connect Sink Name: ${KCONNECT_NAME}"
  sed -i.bak "2s|.*|    \"name\": \"${KCONNECT_NAME}\",|" $CONNECTOR_FILE
  # 4 "topic"
  sed -i.bak "4s|.*|        \"topics\": \"${TESTING_TOPIC}\",|" $CONNECTOR_FILE
  # 12 "connection.uri"
  sed -i.bak "12s|.*|        \"connection.uri\": \"${MONGODB_CONN_URL}\",|" $CONNECTOR_FILE
  # 13 "database"
  sed -i.bak "13s|.*|        \"database\": \"${DATABASE}\",|" $CONNECTOR_FILE
  # 14 "collection"
  sed -i.bak "14s|.*|        \"collection\": \"${COLLECTION}\",|" $CONNECTOR_FILE

  # Portforward to kafkaconnect pod & Create Request
  KCONNECT_POD=`kubectl get pods -n kafka | grep kconnect-cluster-connect | awk '{print $1}'`
  echo "Kafka Connect Pod: ${KCONNECT_POD}"
  kubectl -n kafka port-forward $KCONNECT_POD 8083:8083 &
  KCONNECT_PORT_FORWARD_PID=$!

  sleep 5

  curl -H 'Content-Type: application/json' -X POST -d @$CONNECTOR_FILE http://localhost:8083/connectors

  sleep 5
  kill $KCONNECT_PORT_FORWARD_PID
}

remove_kafka_connect_connector()
{
  # Portforward to kafkaconnect pod & Create Request
  KCONNECT_POD=`kubectl get pods -n kafka | grep kconnect-cluster-connect | awk '{print $1}'`
  echo "Kafka Connect Pod: ${KCONNECT_POD}"
  kubectl -n kafka port-forward $KCONNECT_POD 8083:8083 &
  KCONNECT_PORT_FORWARD_PID=$!

  sleep 5
  
  curl -X DELETE http://localhost:8083/connectors/$KCONNECT_NAME

  sleep 5
  kill $KCONNECT_PORT_FORWARD_PID
}

#### MAIN --------------------------------

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

# Deploy test topic
create_and_deploy_kafka_test_topic_yaml $TESTING_TOPIC

kubectl apply -f temp/${TESTING_TOPIC}/kafka-test-topic.yaml

sleep 2

# Create Kafkacat configuration based if TLS/SSL enforcement is enabled
if [ $MTLS_ON == true ]; then
    # TLS Enabled on cluster
    echo "${YELLOW}Configuring Kafkacat with SSL${NC}"
    # Deploy test user with access to test topic
    create_and_deploy_kafka_test_user_yaml $TESTING_TOPIC

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
  
  else 
    echo "${YELLOW}Configuring Kafkacat without SSL${NC}"
    # TLS Disabled on cluster
    # Create kafkacat.config file
    echo "bootstrap.servers=${BROKER_EXTERNAL_ADDRESS}" > temp/${TESTING_TOPIC}/kafkacat.config
fi

# Deploy Kafka Connect Sink
if [ $K_CONNECT_ON == true ]; then
  deploy_kafka_connect_connector
fi

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
cleanup_cluster $TESTING_TOPIC

# Deploy Kafka Connect Sink
if [ $K_CONNECT_ON == true ]; then
  remove_kafka_connect_connector
fi

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