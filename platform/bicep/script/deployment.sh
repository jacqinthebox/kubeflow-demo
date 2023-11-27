#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="rg-kubeflow-d-westeurope-02"
TEMPLATE_FILE="../environments/dev/main.bicep"
PARAMETERS_FILE="../environments/dev/parameters.json"
LOCATION="westeurope"

if [ "$1" == "init" ]; then
    echo "Initialize deployment..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    az configure --defaults group=$RESOURCE_GROUP
    az deployment group what-if --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE --parameters @$PARAMETERS_FILE
elif [ "$1" == "apply" ]; then
    echo "Deploying Bicep template..."
    az deployment group create --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE --parameters @$PARAMETERS_FILE
elif [ "$1" == "destroy" ]; then
    echo "Destroying resource group..."
    az group delete --name $RESOURCE_GROUP --yes
else
    echo "Invalid argument." 
    echo "Usage: ./deployment.sh [init|apply|destroy]"
    echo "Usage: RESOURCE_GROUP=my-resource-group TEMPLATE_FILE=main.bicep LOCATION=westeurope ./bicep.sh [init|apply|destroy]"
fi