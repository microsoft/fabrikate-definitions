#!/bin/bash
set +x

source ./common.sh

if [ "$CA_CRT" ];
then
    echo "Preparing truststore"
    TRUSTSTORE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    echo "$CA_CRT" > /tmp/ca.crt
    create_truststore /opt/kafka/truststore.p12 "$TRUSTSTORE_PASSWORD" /tmp/ca.crt ca
fi

if [[ "$USER_CRT" && "$USER_KEY" ]];
then
    echo "Preparing keystore"
    KEYSTORE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    echo "$USER_CRT" > /tmp/user.crt
    echo "$USER_KEY" > /tmp/user.key
    create_keystore /opt/kafka/keystore.p12 "$KEYSTORE_PASSWORD" /tmp/user.crt /tmp/user.key /tmp/ca.crt "$HOSTNAME"
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
