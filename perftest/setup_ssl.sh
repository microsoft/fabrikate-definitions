#!/bin/bash
set +x

# Parameters:
# $1: Path to the new truststore
# $2: Truststore password
# $3: Public key to be imported
# $4: Alias of the certificate
function create_truststore {
    if [ -f "$1" ]; then
        echo "Truststore exists so removing it since we are using a new random password."
        rm -f "$1"
    fi
    keytool -keystore "$1" -storepass "$2" -noprompt -alias "$4" -import -file "$3" -storetype PKCS12
}

# Parameters:
# $1: Path to the new keystore
# $2: Truststore password
# $3: Public key to be imported
# $4: Private key to be imported
# $5: Alias of the certificate
function create_keystore {
    if ! hash openssl; then
        if hash apt-get; then
            apt-get update && apt-get install openssl -y
        else
            echo "FAILED TO CREATED KEYSTORE!"
            exit 1
        fi
    fi
    if [ -f "$1" ]; then
        echo "Keystore exists so removing it since we are using a new random password."
        rm -f "$1"
    fi
    RANDFILE=/tmp/.rnd openssl pkcs12 -export -in "$3" -inkey "$4" -name "$HOSTNAME" -password "pass:$2" -out "$1"
}

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