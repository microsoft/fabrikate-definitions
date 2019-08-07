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
  - Currently TLS is _not_ supported for this test
- `kafkacat` needs to be installed and added to $PATH
  - [Kafkacat Installation](https://github.com/edenhill/kafkacat#install)

### Running the test

Simply run `sh ./externaltest.sh`. The script will retrieve the broker's external address 
The test results will displayed at the end. The script with exit with code 0 for success and 1 for failure.