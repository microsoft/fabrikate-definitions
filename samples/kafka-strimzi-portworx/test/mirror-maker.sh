kubectl apply -n kafka -f kafka-topics.yaml
kubectl apply -n kafka -f kafka-users.yaml
kubectl apply -n kafka -f kafka-client.yaml

sleep 5s

setup_kafka_client_ssl () {
  echo "Setting Up Kafka Client for SSL"
  for i in $(seq 0 2); do # End Number is replication factor of kafka client - 1
    kubectl cp ./client_helpers/common.sh "kafka/kafkaclient-$i:/opt/kafka/"
    kubectl cp ./client_helpers/mirrormaker_ssl.sh "kafka/kafkaclient-$i:/opt/kafka/"
    kubectl exec -n kafka -it "kafkaclient-$i" -- bash perftest_ssl.sh
  done
}

setup_kafka_client_ssl

echo "finished setting up kafka ssl"

kubectl create -f ../mirror-maker/mirror-maker.yaml

echo "finished deploying mirror maker"