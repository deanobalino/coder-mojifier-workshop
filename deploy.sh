#!/bin/bash

# Change these parameters
PROJECT_NAME=mojifier
PASSWORD=password
#NEW_UUID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
NEW_UUID=vhvbchv
echo $NEW_UUID
STORAGE_ACCOUNT_NAME=$PROJECT_NAME$NEW_UUID
RESOURCE_GROUP=$PROJECT_NAME-workshop11
LOCATION=westeurope
SHARE_NAME_PROJ=code-server-proj
SHARE_NAME_DATA=code-server-data
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
echo -e "${BLUE}====== Beginning Deployment ======\n"
echo -e "${RED}All Logs can be found in log/coder-deploy.log\n"
#make the log dir
mkdir log
# Create the resource group
echo -e "${BLUE}Creating the Resource Group\n"
az group create --name $RESOURCE_GROUP --location $LOCATION   

# Create the storage account with the parameters
echo -e "${BLUE}Creating the Storage account\n"
az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP -l $LOCATION --sku Standard_LRS -o table   
# Export the connection string as an environment variable, this is used when creating the Azure file share
CONN_STR=$(az storage account show-connection-string -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP -o tsv)
# Create the shares
echo -e "${BLUE}Creating the File Shares\n"
az storage share create -n $SHARE_NAME_PROJ --connection-string $CONN_STR -o table  
az storage share create -n $SHARE_NAME_DATA --connection-string $CONN_STR -o table  

# Get the account name and key
STORAGE_ACCOUNT=$(az storage account list --resource-group $RESOURCE_GROUP --query "[?contains(name,'$STORAGE_ACCOUNT_NAME')].[name]" -o tsv)
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

echo -e "${BLUE}Creating YAML File for Azure Container Instance\n"
cat > acideploy.yaml <<EOL
apiVersion: 2018-10-01
location: ${LOCATION}
name: ${PROJECT_NAME}
properties:
  containers:
  - name: ${PROJECT_NAME}
    properties:
      command: 
      - '[code-server, ./${PROJECT_NAME},--allow-http,--password=${PASSWORD},--port=3000]'
      image: deanobalino/mojifier:latest
      resources:
        requests:
          cpu: 1.0
          memoryInGb: 1.5
      ports:
      - port: 3000
      volumeMounts:
      - mountPath: /root/project
        name: ${SHARE_NAME_PROJ}
      - mountPath: /root/data
        name: ${SHARE_NAME_DATA}
  osType: Linux
  restartPolicy: Always
  volumes:
  - azureFile:
      shareName: ${SHARE_NAME_PROJ}
      storageAccountName: ${STORAGE_ACCOUNT}
      storageAccountKey: ${STORAGE_KEY}
    name: ${SHARE_NAME_PROJ}
  - azureFile:
      shareName: ${SHARE_NAME_DATA}
      storageAccountName: ${STORAGE_ACCOUNT}
      storageAccountKey: ${STORAGE_KEY}
    name: ${SHARE_NAME_DATA}
  ipAddress:
    dnsNameLabel: ${STORAGE_ACCOUNT_NAME}
    type: Public
    ports:
    - port: '3000'
      protocol: tcp
tags: {}
type: Microsoft.ContainerInstance/containerGroups
EOL

echo -e "${BLUE} Deploying the container instance\n"
az container create --resource-group $RESOURCE_GROUP --file acideploy.yaml  



CONTAINER_URL=$(az container show --resource-group $RESOURCE_GROUP --name $PROJECT_NAME --query ipAddress.fqdn -o tsv)

echo ""
echo -e "${GREEN}====== Deployment Complete ======\n"
echo -e "${RED}====== Connection Details ======\n"
echo -e "${RED}- Container URL:     http://$CONTAINER_URL:3000\n"
echo ""
