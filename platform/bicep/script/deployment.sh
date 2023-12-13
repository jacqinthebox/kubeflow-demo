#!/bin/bash
set -euo pipefail

# Set variables
SUFFIX="kf-dev-we-01" # this respects the CAF naming convention
TEMPLATE_FILE="../environments/dev/main.bicep" # do not change this
PARAMETERS_FILE="../environments/dev/parameters.json" # do not change this
LOCATION="westeurope" # change to your location
ADMIN_GROUP_OBJECT_ID="your admin group objectid" # (optional) change this to your EntraId admin group object id
FLUX_GIT_REPOSITORY="https://github.com/octocat/Hello-World" # change this to your (forked) git repo
EXPECTED_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000" # your Azure subscription id

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "No arguments provided."
    echo "Usage: ./deployment.sh [init|plan|apply|destroy]"
    exit 1
fi

# Check if logged in to Azure
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "You must be logged in to your Azure subscription to use this script."
    exit 1
fi

# Get the current Azure subscription ID
CURRENT_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Check if the current subscription is the expected one
if [ "$CURRENT_SUBSCRIPTION_ID" != "$EXPECTED_SUBSCRIPTION_ID" ]; then
    echo "You are not in the correct Azure subscription."
    echo "Current Subscription ID: $CURRENT_SUBSCRIPTION_ID"
    echo "Expected Subscription ID: $EXPECTED_SUBSCRIPTION_ID"
    exit 1
fi

# Blatantly pretending to be Terraform
RESOURCE_GROUP=rg-${SUFFIX}

if [ "$1" == "init" ]; then
    echo "Initializing for deployment.."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    az configure --defaults group=$RESOURCE_GROUP
elif [ "$1" == "plan" ]; then
    echo "Showing changes required by the current configuration..."
    az deployment group what-if --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE --parameters @$PARAMETERS_FILE --parameters adminGroupObjectIDs='["'$ADMIN_GROUP_OBJECT_ID'"]' fluxGitRepository=$FLUX_GIT_REPOSITORY
elif [ "$1" == "apply" ]; then
    echo "Create or update infrastructure.."
    az deployment group create --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE --parameters @$PARAMETERS_FILE --parameters adminGroupObjectIDs='["'$ADMIN_GROUP_OBJECT_ID'"]' fluxGitRepository=$FLUX_GIT_REPOSITORY

elif [ "$1" == "destroy" ]; then
    echo "Destroying resource group..."
    az group delete --name $RESOURCE_GROUP --yes
else
    echo "Invalid argument."
    echo "Usage: ./deployment.sh [init|plan|apply|destroy]"
    echo "Usage: RESOURCE_GROUP=my-resource-group TEMPLATE_FILE=main.bicep LOCATION=westeurope ./bicep.sh [init|apply|destroy]"
fi
