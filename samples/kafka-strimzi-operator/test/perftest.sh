#! /usr/bin/env bash

# Set correct values for your Kafka Cluster
if [ -z "$KAFKA_BROKER_NAME" ]; then
  # Switch if you don't want to use ssl.
  KAFKA_BROKER_NAME="kcluster-kafka-brokers.kafka:9093"
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

# Comment following line if you don't want to use ssl.
setup_kafka_client_ssl

echo -e "\nSingle thread, no replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
  --topic test-one-rep --num-records $NUM_RECORDS --record-size $RECORD_SIZE \
  --throughput $THROUGHPUT --producer-props \
  acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 \
  --producer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\nSingle-thread, async 3x replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
 --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE \
 --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME \
  buffer.memory=$BUFFER_MEMORY batch.size=8196 --producer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\nSingle-thread, sync 3x replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
 --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT \
 --producer-props acks=-1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY \
  batch.size=64000 --producer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\nThree Producers, 3x async replication"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
 --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT \
 --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY  \
 batch.size=8196 --producer.config /opt/kafka/config/ssl-config.properties
kubectl exec -n kafka -it kafkaclient-1 -- bin/kafka-producer-perf-test.sh \
 --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT \
 --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY  \
 batch.size=8196 --producer.config /opt/kafka/config/ssl-config.properties
kubectl exec -it -n kafka kafkaclient-2 -- bin/kafka-producer-perf-test.sh \
 --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT \
 --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY \
 batch.size=8196 --producer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\nConsumer throughput"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-consumer-perf-test.sh \
--broker-list $KAFKA_BROKER_NAME --messages $NUM_RECORDS --topic test --threads 1 \
--consumer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\n3 Consumers"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-consumer-perf-test.sh \
--broker-list $KAFKA_BROKER_NAME --messages $NUM_RECORDS --topic test --threads 1 \
--consumer.config /opt/kafka/config/ssl-config.properties
kubectl exec -it kafkaclient-1 -- bin/kafka-consumer-perf-test.sh \
--broker-list $KAFKA_BROKER_NAME --messages $NUM_RECORDS --topic test --threads 1 \
--consumer.config /opt/kafka/config/ssl-config.properties
kubectl exec -it kafkaclient-2 -- bin/kafka-consumer-perf-test.sh \
--broker-list $KAFKA_BROKER_NAME --messages $NUM_RECORDS --topic test --threads 1 \
--consumer.config /opt/kafka/config/ssl-config.properties

sleep 3s

echo -e "\nProducer and Consumer"
kubectl exec -n kafka -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh \
 --topic test-producer-consumer --num-records $NUM_RECORDS --record-size $RECORD_SIZE \
 --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME \
 buffer.memory=$BUFFER_MEMORY batch.size=8196 --producer.config /opt/kafka/config/ssl-config.properties
kubectl exec -n kafka -it kafkaclient-1 -- bin/kafka-consumer-perf-test.sh \
--broker-list $KAFKA_BROKER_NAME --messages $NUM_RECORDS --topic test-producer-consumer --threads 1 \
--consumer.config /opt/kafka/config/ssl-config.properties
