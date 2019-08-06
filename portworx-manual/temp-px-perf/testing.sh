export TESTING_TOPIC="topic-3305220c-f2cb-4780-8f56-040405b972d3"
echo ${TESTING_TOPIC}
MESSAGE_OUTPUT_FILE_SNAPSHOT="./temp/${TESTING_TOPIC}-snapshot-output-messages.txt"
echo $MESSAGE_OUTPUT_FILE_SNAPSHOT
echo "Kafka broker messages after snapshot are written at: " $MESSAGE_OUTPUT_FILE_SNAPSHOT
kubectl exec -n kafka -i kafkaclient-0 -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic $TESTING_TOPIC --from-beginning > ${MESSAGE_OUTPUT_FILE_SNAPSHOT} &
CONSUMER_PID=$!
sleep 10
kill $CONSUMER_PID
echo