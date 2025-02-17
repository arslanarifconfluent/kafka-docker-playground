#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../../scripts/utils.sh



if [ ! -z "$AZ_USER" ] && [ ! -z "$AZ_PASS" ]
then
    log "Logging to Azure using environment variables AZ_USER and AZ_PASS"
    set +e
    az logout
    set -e
    az login -u "$AZ_USER" -p "$AZ_PASS" > /dev/null 2>&1
else
    log "Logging to Azure using browser"
    az login
fi

AZURE_NAME=pg${USER}f${GITHUB_RUN_NUMBER}${TAG}
AZURE_NAME=${AZURE_NAME//[-._]/}
AZURE_RESOURCE_GROUP=$AZURE_NAME
AZURE_STORAGE_NAME=$AZURE_NAME
AZURE_FUNCTIONS_NAME=$AZURE_NAME
AZURE_REGION=westeurope

set +e
az group delete --name $AZURE_RESOURCE_GROUP --yes
rm -rf $PWD/LocalFunctionProj
set -e

log "Creating resource $AZURE_RESOURCE_GROUP in $AZURE_REGION"
az group create \
    --name $AZURE_RESOURCE_GROUP \
    --location $AZURE_REGION \
    --tags owner_email=$AZ_USER

log "Creating storage account $AZURE_STORAGE_NAME in resource $AZURE_RESOURCE_GROUP"
az storage account create \
    --name $AZURE_STORAGE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --location $AZURE_REGION \
    --sku Standard_LRS

rm -rf $PWD/LocalFunctionProj
log "Creating local functions project with HTTP trigger"
# https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli?pivots=programming-language-javascript&tabs=bash%2Cbrowser
docker run -v $PWD/LocalFunctionProj:/LocalFunctionProj mcr.microsoft.com/azure-functions/node:3.0-node12-core-tools bash -c "func init LocalFunctionProj --javascript && cd LocalFunctionProj && func new --name HttpExample --template \"HTTP trigger\" --authlevel \"anonymous\""

log "Creating functions app $AZURE_FUNCTIONS_NAME"
az functionapp create --consumption-plan-location $AZURE_REGION --name $AZURE_FUNCTIONS_NAME --resource-group $AZURE_RESOURCE_GROUP --runtime node --storage-account $AZURE_STORAGE_NAME --runtime-version 14 --functions-version 3 --tags owner_email=$AZ_USER

log "Publishing functions app, it will take a while"
max_attempts="10"
sleep_interval="60"
attempt_num=1

until docker run -v $PWD/LocalFunctionProj:/LocalFunctionProj mcr.microsoft.com/azure-functions/node:3.0-node12-core-tools bash -c "az login -u \"$AZ_USER\" -p \"$AZ_PASS\" && cd LocalFunctionProj && func azure functionapp publish \"$AZURE_FUNCTIONS_NAME\""
do
    if (( attempt_num == max_attempts ))
    then
        logerror "ERROR: Failed after $attempt_num attempts. Please troubleshoot and run again."
        exit 1
    else
        log "Retrying after $sleep_interval seconds"
        ((attempt_num++))
        sleep $sleep_interval
    fi
done


output=$(docker run -v $PWD/LocalFunctionProj:/LocalFunctionProj mcr.microsoft.com/azure-functions/node:3.0-node12-core-tools bash -c "az login -u \"$AZ_USER\" -p \"$AZ_PASS\" > /dev/null && cd LocalFunctionProj && func azure functionapp list-functions $AZURE_FUNCTIONS_NAME --show-keys")
FUNCTIONS_URL=$(echo $output | grep -Eo 'https://[^ >]+'|head -1)

log "Functions URL is $FUNCTIONS_URL"

${DIR}/../../environment/plaintext/start.sh "${PWD}/docker-compose.plaintext.yml"

log "Sending messages to topic functions-test"
playground topic produce -t functions-test --nb-messages 3 --key "key1" << 'EOF'
value%g
EOF

log "Creating Azure Functions Sink connector"
playground connector create-or-update --connector azure-functions-sink << EOF
{
    "connector.class": "io.confluent.connect.azure.functions.AzureFunctionsSinkConnector",
    "tasks.max": "1",
    "topics": "functions-test",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter":"org.apache.kafka.connect.storage.StringConverter",
    "function.url": "$FUNCTIONS_URL",
    "function.key": "",
    "confluent.license": "",
    "confluent.topic.bootstrap.servers": "broker:9092",
    "confluent.topic.replication.factor": "1",
    "reporter.bootstrap.servers": "broker:9092",
    "reporter.error.topic.name": "test-error",
    "reporter.error.topic.replication.factor": 1,
    "reporter.error.topic.key.format": "string",
    "reporter.error.topic.value.format": "string",
    "reporter.result.topic.name": "test-result",
    "reporter.result.topic.key.format": "string",
    "reporter.result.topic.value.format": "string",
    "reporter.result.topic.replication.factor": 1
}
EOF


sleep 10

log "Confirm that the messages were delivered to the result topic in Kafka"
playground topic consume --topic test-result --min-expected-messages 3 --timeout 60

log "Deleting resource group"
az group delete --name $AZURE_RESOURCE_GROUP --yes --no-wait
