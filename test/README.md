# Strimzi Operator Kafka Tests

This directory contains simple test scripts to check if a Strimzi Operator Kafka cluster is live. 

## Requirements

- A kubernetes cluster with Kafka deployed via Strimzi Operator

## Liveness Check from Inside the cluster
### Test Requirements
- `kubectl` should be configured to point to this cluster

### Running the test

Simply run `sh ./internaltest.sh`. The script will create and deploy a kafka client to act as a sample producer and consumer.

The test results will displayed at the end. The script with exit with code 0 for success and 1 for failure.

## Liveness Check from Outside the cluster
### Test Requirements
- `kubectl` should be configured to point to this cluster
- The Kafka deployment should be configured with an external loadbalancer listener.
  - [Reference Guide](https://strimzi.io/2019/05/13/accessing-kafka-part-4.html)
  - The External LoadBalancer can have TLS enabled or disabled.
- `kafkacat` needs to be installed and added to $PATH
  - on systems with homebrew installed, you can run `brew install kafkacat`
  - [Kafkacat Installation](https://github.com/edenhill/kafkacat#install)
- Optionally, Kafka Connect can be tested if there is a backing database for it.
  - Instructions can be found under the [kafka connect examples](../examples/kafka_connect)
  - After the test is run, you can check the collection for the test messages

### Running the test

Run the testing script as configured below:
- If the External LoadBalancer is enabled with TLS support: `sh ./externaltest.sh -t`
- If the External LoadBalancer is NOT enabled with TLS support: `sh ./externaltest.sh`
- If kafkaconnect is enabled:
  -  export three variables in your shell:
        ```
            export MONGODB_CONN_URL='<mongodb-connection-string>'
            export DATABASE='<database-name>'
            export COLLECTION'<collection-name>'
        ```
  - add the `-k` flag to the arguments: `sh ./externaltest.sh -t -k`
  
The script will deploy a test topic and connect to the brokers through the external loadbalancer IP, utilizing kafkacat as a producer and consumer.
The test results will displayed at the end. The script with exit with code 0 for success and 1 for failure.

# Replication

A sample configuration for mirror maker is included with the repo. Upload the destination cluster's certificate into a secret called `mirrormaker-cluster-ca-cert` in the `kafka` namespace, and add the IP address of the destination cluster's broker into `mirror-maker.yaml`. You will also need to create a KafkaUser for the second cluster in order to authenticate Mirror Maker with your cluster. To test out Mirror Maker, run ./test/mirror-maker.sh to set up clients within the Kafka namespace authenticated with mutual TLS authentication. You can then test out replication by using the kafkaclient pods:

```
kubectl exec -it kafkaclient-0 --namespace kafka -- /bin/bash
./bin/kafka-console-producer.sh --broker-list kcluster-kafka-bootstrap:9093 --topic test-replication --producer.config config/client-ssl.properties

kubectl exec -it kafkaclient-1 --namespace kafka -- /bin/bash
./bin/kafka-console-consumer.sh --bootstrap-server <DEST-IP>:9094 --topic test-replication --consumer.config config/mm-client-ssl.properties --from-beginning
```