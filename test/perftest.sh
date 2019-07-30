#! /usr/bin/env bash

# Set correct values for your Kafka Cluster
if [ -z "$KAFKA_BROKER_NAME" ]; then
  # Switch if you don't want to use ssl.
  KAFKA_BROKER_NAME="kcluster-kafka-brokers.kafka:9093"
fi
if [ -z "$ZOOKEEPER_NAME" ]; then
  # This doesn't work - can't connect directly to zookeeper (Strimzi Operator Feature)
  ZOOKEEPER_NAME="kcluster-zookeeper-client.kafka:2181"
fi
if [ -z "$NUM_RECORDS" ]; then
  NUM_RECORDS=50000000
fi
if [ -z "$RECORD_SIZE" ]; then
  RECORD_SIZE=100
fi
if [ -z "$THROUGHPUT" ]; then
  THROUGHPUT=-1
fi
if [ -z "$BUFFER_MEMORY" ]; then
  BUFFER_MEMORY=67108864
fi

kubectl apply -n kafka -f kafka-topics.yaml
kubectl apply -n kafka -f kafka-users.yaml
kubectl apply -n kafka -f kafka-client.yaml

sleep 5s

setup_kafka_client_ssl () {
  echo "Setting Up Kafka Client for SSL"
  for i in $(seq 0 2); do # End Number is replication factor of kafka client - 1
    kubectl cp ./client_helpers/common.sh "kafka/kafkaclient-$i:/opt/kafka/"
    kubectl cp ./client_helpers/perftest_ssl.sh "kafka/kafkaclient-$i:/opt/kafka/"
    kubectl exec -n kafka -it "kafkaclient-$i" -- bash perftest_ssl.sh
  done
}

# Create topics
# kubectl exec -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper $ZOOKEEPER_NAME --create --topic test-rep-one --partitions 6 --replication-factor 1
# kubectl exec -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper $ZOOKEEPER_NAME --create --topic test --partitions 6 --replication-factor 3 

# Comment following line if you don't want to use ssl.
setup_kafka_client_ssl

echo "Single thread, no replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
  --topic test-one-rep --num-records $NUM_RECORDS --record-size $RECORD_SIZE \
  --throughput $THROUGHPUT --producer-props \
  acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 \
  --producer.config /opt/kafka/config/ssl-config.properties

exit 1

echo "Single-thread, async 3x replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

echo "Single-thread, sync 3x replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=-1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=64000

echo "Three Producers, 3x async replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 && kubectl exec -it kafkaclient-1 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 && kubectl exec -it kafkaclient-2 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

# Throughput Versus Stored Data - this is a long, memory intensive test. Uncomment and use with caution
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper kafka-zookeeper:2181 --create --topic test-throughput --partitions 6 --replication-factor 3 
# kubectl exec -n kafka -it kafkaclient-1 -- bin/kafka-producer-perf-test.sh --topic test-throughput --num-records 50000000000 --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

# Effect of message size

# for i in 10 100 1000 10000 100000;
# do
# echo ""
# echo $i
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $((1000*1024*1024/$i)) --record-size $i --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=128000
# done;

# echo "Consumer throughput"
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-consumer-perf-test.sh --zookeeper $ZOOKEEPER_NAME --messages $NUM_RECORDS --topic test --threads 1

# echo "3 Consumers"
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-consumer-perf-test.sh --zookeeper $ZOOKEEPER_NAME --messages $NUM_RECORDS --topic test --threads 1 && kubectl exec -it kafkaclient-1 -- bin/kafka-consumer-perf-test.sh --zookeeper $ZOOKEEPER_NAME --messages $NUM_RECORDS --topic test --threads 1 && kubectl exec -it kafkaclient-2 -- bin/kafka-consumer-perf-test.sh --zookeeper $ZOOKEEPER_NAME --messages $NUM_RECORDS --topic test --threads 1

# End-to-end Latency - does not work, can't find class kafka.tools?
# kubectl exec -n kafka -it kafkaclient -- bin/kafka-run-class.sh kafka.tools.TestEndToEndLatency esv4-hcl198.grid.linkedin.com:9092 esv4-hcl197.grid.linkedin.com:2181 test 5000

# These do not currently work since you can't connect to zookeeper.
# echo "Producer and Consumer"
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper $ZOOKEEPER_NAME --create --topic test-producer-consumer --partitions 6 --replication-factor 3 
# kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test-producer-consumer --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196
# kubectl exec -n kafka -it kafkaclient-1 -- bin/kafka-consumer-perf-test.sh --zookeeper $ZOOKEEPER_NAME --messages $NUM_RECORDS --topic test-producer-consumer --threads 1
