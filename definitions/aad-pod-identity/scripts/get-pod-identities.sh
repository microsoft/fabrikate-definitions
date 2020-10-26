#/bin/bash

CONFIG_FILE=${2:-"./config/common.yaml"}

IDENTITIES=$(az identity list -g "$1" --query "[*].{id:id,name:name,clientId:clientId}")
for identity in $(echo "${IDENTITIES}" | jq -r '.[] | @base64'); do
  ID_CLIENT_ID=$(echo ${identity} | base64 --decode | jq -r '.clientId')
  ID_RESRCE_ID=$(echo ${identity} | base64 --decode | jq -r '.id')
  ID_NAME=$(echo ${identity} | base64 --decode | jq -r '.name')

  TMP_FILE=$(mktemp)

  # create the AzureIdentity object for the aad-pod-identity helm chart
  yq write ${TMP_FILE} 'name' "${ID_NAME}" -i --style double
  yq write ${TMP_FILE} 'namespace' 'default' -i --style double
  yq write ${TMP_FILE} 'type' '0' -i
  yq write ${TMP_FILE} 'resourceID' "${ID_RESRCE_ID}" -i --style double
  yq write ${TMP_FILE} 'clientID' "${ID_CLIENT_ID}" -i --style double
  yq write ${TMP_FILE} 'binding.name' "${ID_NAME}-binding" -i --style double
  yq write ${TMP_FILE} 'binding.selector' "${ID_NAME}" -i --style double

  # nest the object to match the config for aad-pod-identity
  yq prefix ${TMP_FILE} 'subcomponents.aad-pod-identity.config.azureIdentities[+]' -i

  # merge the temp file and the proper config file
  yq merge ${CONFIG_FILE} ${TMP_FILE} -i
done
