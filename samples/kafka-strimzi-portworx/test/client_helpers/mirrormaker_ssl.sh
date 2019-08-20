#!/bin/bash
set +x

source ./common.sh

if [ "$CA_CRT" ];
then
    echo "Preparing truststore"
    TRUSTSTORE_PASSWORD1=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    echo "$CA_CRT" > /tmp/ca.crt
    create_truststore /opt/kafka/truststore1.p12 "$TRUSTSTORE_PASSWORD1" /tmp/ca.crt ca
fi

if [ "$MM_CA_CRT" ];
then
    echo "Preparing truststore"
    MM_TRUSTSTORE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    echo "$CA_CRT" > /tmp/mm-ca.crt
    create_truststore /opt/kafka/truststore2.p12 "$MM_TRUSTSTORE_PASSWORD" /tmp/mm-ca.crt mm-ca
fi

if [[ "$USER_CRT" && "$USER_KEY" ]];
then
    echo "Preparing keystore"
    KEYSTORE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    echo "$USER_CRT" > /tmp/user.crt
    echo "$USER_KEY" > /tmp/user.key
    create_keystore /opt/kafka/keystore.p12 "$KEYSTORE_PASSWORD" /tmp/user.crt /tmp/user.key /tmp/ca.crt "$HOSTNAME"
    create_keystore /opt/kafka/mm-keystore.p12 "$KEYSTORE_PASSWORD" /tmp/user.crt /tmp/user.key /tmp/mm-ca.crt "$HOSTNAME"
fi

cat << EOF > /opt/kafka/config/ssl-config.properties
security.protocol=SSL
ssl.truststore.location=/opt/kafka/truststore.p12
ssl.truststore.password=$TRUSTSTORE_PASSWORD
ssl.truststore.type=PKCS12
ssl.keystore.location=/opt/kafka/keystore.p12
ssl.keystore.password=$KEYSTORE_PASSWORD
ssl.keystore.type=PKCS12
ssl.key.password=$KEYSTORE_PASSWORD
EOF

cat << EOF > /opt/kafka/config/mm-ssl-config.properties
security.protocol=SSL
ssl.truststore.location=/opt/kafka/mm-truststore.p12
ssl.truststore.password=$MM_TRUSTSTORE_PASSWORD
ssl.truststore.type=PKCS12
ssl.keystore.location=/opt/kafka/mm-keystore.p12
ssl.keystore.password=$KEYSTORE_PASSWORD
ssl.keystore.type=PKCS12
ssl.key.password=$KEYSTORE_PASSWORD
EOF