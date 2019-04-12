#!/bin/bash

# Change these parameters if you wish
PROJECT_NAME=mojifier
LOCATION=westeurope
SHARE_NAME_PROJ=code-server-proj
SHARE_NAME_DATA=code-server-data

# Get password from command line arguments  -p
while getopts ":p:" opt; do
  case $opt in
    p) PASSWORD="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

#Generate a 10 charachter Unique ID to append to resource names
NEW_UUID=$(od -x /dev/urandom | head -1 | awk '{OFS=""; srand($6); sub(/./,"4",$5); sub(/./,substr("89ab",rand()*4,1),$6); print $2$3,$4,$5,$6,$7$8$9}' | cut -c22-)
# Set colors for terminal output
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
# Set Parameters
STORAGE_ACCOUNT_NAME=$PROJECT_NAME$NEW_UUID
RESOURCE_GROUP=$PROJECT_NAME-workshop$NEW_UUID



echo "                                                                      "
echo " __  __    ____         _   _____   ______   _____   ______   _____   "
echo "|  \/  |  / __ \       | | |_   _| |  ____| |_   _| |  ____| |  __ \  "
echo "| \  / | | |  | |      | |   | |   | |__      | |   | |__    | |__) | "
echo "| |\/| | | |  | |  _   | |   | |   |  __|     | |   |  __|   |  _  /  "
echo "| |  | | | |__| | | |__| |  _| |_  | |       _| |_  | |____  | | \ \  "
echo "|_|  |_|  \____/   \____/  |_____| |_|      |_____| |______| |_|  \_\ "
echo "                                                                      "

echo -e "${BLUE}====== Beginning Deployment ======\n"
echo -e "${RED}All Logs can be found in log/coder-deploy.log\n"
mkdir log
# Create the resource group
echo -e "${BLUE}Creating the Resource Group\n"
az group create --name $RESOURCE_GROUP --location $LOCATION  &> log/coder-deploy.log

# Create the storage account with the parameters
echo -e "${BLUE}Creating the Storage account\n"
az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP -l $LOCATION --sku Standard_LRS -o table &>> log/coder-deploy.log  
# Export the connection string as an environment variable, this is used when creating the Azure file share
CONN_STR=$(az storage account show-connection-string -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP -o tsv)
# Create the file shares
echo -e "${BLUE}Creating the File Shares\n"
az storage share create -n $SHARE_NAME_PROJ --connection-string $CONN_STR -o table  &>> log/coder-deploy.log
az storage share create -n $SHARE_NAME_DATA --connection-string $CONN_STR -o table  &>> log/coder-deploy.log

# Get the account name and key
STORAGE_ACCOUNT=$(az storage account list --resource-group $RESOURCE_GROUP --query "[?contains(name,'$STORAGE_ACCOUNT_NAME')].[name]" -o tsv)
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

# Create YAML file
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
      - code-server 
      - ./mojifier 
      - --allow-http 
      - --password=$PASSWORD 
      - --port=3000
      image: deanobalino/mojifier:latest
      resources:
        requests:
          cpu: 1.0
          memoryInGb: 1.5
      volumeMounts:
      - mountPath: /root/project
        name: project-volume
      - mountPath: /root/.local/share/code-server
        name: data-volume
      ports:
      - port: 3000
  osType: Linux
  restartPolicy: Always
  volumes:
  - name: project-volume
    azureFile:
      shareName: ${SHARE_NAME_PROJ}
      storageAccountName: ${STORAGE_ACCOUNT}
      storageAccountKey: ${STORAGE_KEY}
  - name: data-volume
    azureFile:
      shareName: ${SHARE_NAME_DATA}
      storageAccountName: ${STORAGE_ACCOUNT}
      storageAccountKey: ${STORAGE_KEY}
  ipAddress:
    dnsNameLabel: ${STORAGE_ACCOUNT_NAME}
    type: Public
    ports:
    - port: 3000
      protocol: tcp
tags: null
type: Microsoft.ContainerInstance/containerGroups
EOL &>> log/coder-deploy.log

echo -e "${BLUE} Deploying the container instance - Be Patient, this may take a while\n"
az container create --resource-group $RESOURCE_GROUP --file acideploy.yaml  &>> log/coder-deploy.log

CONTAINER_URL=$(az container show --resource-group $RESOURCE_GROUP --name $PROJECT_NAME --query ipAddress.fqdn -o tsv)

# echo -e "${BLUE} Installing Extensions\n"
# apt-get update && apt-get install -y bsdtar &>> log/coder-deploy.log
# # Install Azure Functions Extension
# curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-azuretools/vsextensions/vscode-azurefunctions/0.15.0/vspackage > func.vxif &>> log/coder-deploy.log
# bsdtar -xvf func.vxif &>> log/coder-deploy.log &>> log/coder-deploy.log
# az storage file upload-batch --destination $SHARE_NAME_DATA --source extension --connection-string=$CONN_STR --destination-path extensions/ms-azuretools.vscode-azurefunctions-0.15.0 &>> log/coder-deploy.log
# rm func.vxif &>> log/coder-deploy.log
# rm extension.vsixmanifest &>> log/coder-deploy.log
# rm -rf extension &>> log/coder-deploy.log
# # Install Azure Account Extension
# curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/azure-account/0.8.0/vspackage > azAccount.vxif &>> log/coder-deploy.log
# bsdtar -xvf azAccount.vxif &>> log/coder-deploy.log
# az storage file upload-batch --destination $SHARE_NAME_DATA --source extension --connection-string=$CONN_STR --destination-path extensions/ms-vscode.azure-account-0.8.0 &>> log/coder-deploy.log
# rm azAccount.vxif &>> log/coder-deploy.log
# rm extension.vsixmanifest &>> log/coder-deploy.log
# rm -rf extension &>> log/coder-deploy.log

echo ""
echo -e "${GREEN}  ====== Deployment Complete ======\n"
echo -e "${GREEN} ====== Connect at the below URL ======\n"
echo -e "${GREEN}====== http://$CONTAINER_URL:3000 ======\n"
echo -e "${GREEN}   ====== Password: $PASSWORD ======\n"
echo ""

