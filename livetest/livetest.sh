#! /usr/bin/env bash

# TODO: Env vars for argument and configured values for the Kafka Cluster

# Deploy kafka client to use as producer and consumer
# TODO: figure out if we can deploy client without topic and users first?
kubectl apply -n kafka -f kafka-topics.yaml
kubectl apply -n kafka -f kafka-users.yaml
kubectl apply -n kafka -f kafka-client.yaml
sleep 5s

# Kafka client SSL Components
setup_kafka_client_ssl () {
  echo "Setting Up Kafka Client for SSL"
  for i in $(seq 0 2); do # End Number is replication factor of kafka client - 1
    kubectl cp ./setup_ssl.sh "kafka/kafkaclient-$i:/opt/kafka/setup_ssl.sh"
    kubectl exec -n kafka -it "kafkaclient-$i" -- bash setup_ssl.sh
  done
}

# TODO: argument or boolean for this
# Comment following line if you don't want to use ssl.
# setup_kafka_client_ssl

# Create kafka topic
UUID=`uuidgen | awk '{print tolower($0)}'`
echo $UUID

TESTING_TOPIC="topic-${UUID}"
echo "Test Topic: ${TESTING_TOPIC}"

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

# Create messages via console producer
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers:9092 --topic $TESTING_TOPIC < $MESSAGE_INPUT_FILE

# Consume messages from topic
MESSAGE_OUTPUT_FILE="./temp/${TESTING_TOPIC}-output-messages.txt"
# TODO: Figure out how to swallow message "Unable to use a TTY - input is not a terminal or the right kind of file"
# kubectl exec -n kafka -ti kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server kcluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning 2>&1 | tee $MESSAGE_OUTPUT_FILE.txt
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

sleep 60

# Delete test topic
echo "deleting test topic"
echo "kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic ${TESTING_TOPIC}"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $TESTING_TOPIC

echo "listing topics after deletion"
kubectl exec -n kafka -ti kcluster-kafka-0 --container kafka -- bin/kafka-topics.sh --list --zookeeper localhost:2181

# Compare contents of input and output
SORTED_INPUT="./temp/sorted-input.txt"
SORTED_OUTPUT="./temp/sorted-output.txt"
sort $MESSAGE_INPUT_FILE > $SORTED_INPUT
sort $MESSAGE_OUTPUT_FILE > $SORTED_OUTPUT

DIFF=`diff ${SORTED_INPUT} ${SORTED_OUTPUT}`
if [ "$DIFF" != "" ] 
then
    echo "Test Failed!!! - There's a difference between input and output!!!"
    exit 1
fi

echo "Test Passed!!! - All input messages are in the output!"
exit 0