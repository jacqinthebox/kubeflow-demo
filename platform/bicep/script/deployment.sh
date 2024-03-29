#!/bin/bash
set -euo pipefail

# Begin config section
# (Required) Your Azure subscription id
EXPECTED_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"

# (Optional) Change this if needed (respects the CAF naming convention)
SUFFIX="ml-d-we-02"

# (Optional) Change this to the desired location
LOCATION="westeurope"
ADMIN_GROUP_OBJECT_ID="00000000-0000-0000-0000-000000000000"
PUBLIC_CLUSTER=true

EXPECTED_SUBSCRIPTION_ID="e267d216-a7aa-42e4-905a-f18316a144c4"

# (Optional) Change this if needed (respects the CAF naming convention)
SUFFIX="ml-d-we-02"

# (Optional) Change this to the desired location
LOCATION="westeurope"
PUBLIC_CLUSTER=true


# (Optional) Change the admin group object id
ADMIN_GROUP_OBJECT_ID="e1ad18a1-95ec-4cc4-8eb4-61a6aeecff1f"

# Change this to your (forked) git repo
FLUX_GIT_REPOSITORY="https://github.com/jacqinthebox/kubeflow-demo"

# Only needed when PUBLIC_CLUSTER=false:
# Change this to your ssh-rsa public key for remote access
SSH_PUBKEY="your ssh-rsa pub key"
# Only needed when CLUSTER_TYPE=private.
# Change this to your ip address for remote access
MY_IP_ADDRESS="your-ip-address"
# End config section


# Main
# Check the value of PUBLIC_CLUSTER
if [ "$PUBLIC_CLUSTER" = true ]; then
    CLUSTER_PATH='public-aks'
else
    CLUSTER_PATH='private-aks'
fi


if [ "$KUBEFLOW" == true ]; then
    PARAMETERS_FILE="../configurations/${CLUSTER_PATH}/kubeflow.parameters.json"
else
    PARAMETERS_FILE="../configurations/${CLUSTER_PATH}/parameters.json"
fi


TEMPLATE_FILE="../configurations/${CLUSTER_PATH}/main.bicep"


if [ "$PUBLIC_CLUSTER" == true ]; then
    EXTRA_PARAMS=()
else
    EXTRA_PARAMS=("sourceAddressPrefix=${MY_IP_ADDRESS}" "adminKey=${SSH_PUBKEY}")
fi


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
    echo "Showing changes required to install or update an aks cluster"
    az deployment group what-if --resource-group $RESOURCE_GROUP \
      --template-file $TEMPLATE_FILE \
      --parameters @$PARAMETERS_FILE \
      --parameters adminGroupObjectIDs='["'$ADMIN_GROUP_OBJECT_ID'"]' suffix=$SUFFIX fluxGitRepository=$FLUX_GIT_REPOSITORY "${EXTRA_PARAMS[@]}"
elif [ "$1" == "apply" ]; then
    echo "Create or update infrastructure.."
    az deployment group create --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE \
      --parameters @$PARAMETERS_FILE \
      --parameters adminGroupObjectIDs='["'$ADMIN_GROUP_OBJECT_ID'"]' suffix=$SUFFIX fluxGitRepository=$FLUX_GIT_REPOSITORY "${EXTRA_PARAMS[@]}"
    echo "Done. Now give your account admin access to the cluster!"
    echo "Run the following command: "
    echo
    objectId=$(az ad signed-in-user show | jq -r .id)
    echo "az role assignment create --assignee $objectId --role "Azure Kubernetes Service RBAC Admin" --scope /subscriptions/${EXPECTED_SUBSCRIPTION_ID}/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/aks-${SUFFIX}"
    echo
elif [ "$1" == "destroy" ]; then
    echo "Destroying resource group..."
    az group delete --name $RESOURCE_GROUP --yes
else
    echo "Invalid argument."
    echo "Usage: ./deployment.sh [init|plan|apply|destroy]"
    echo "Usage: RESOURCE_GROUP=my-resource-group TEMPLATE_FILE=main.bicep LOCATION=westeurope ./bicep.sh [init|apply|destroy]"
fi