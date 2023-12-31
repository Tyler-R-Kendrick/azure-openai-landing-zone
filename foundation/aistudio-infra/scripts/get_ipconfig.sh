#!/bin/bash

RESOURCE_GROUP_NAME=$1

HUB_DNS_NAME="workspace.westus.api.azureml.ms"
HUB_IP=""

while [ -z "${RESOURCE_GROUP_NAME}" ]
do
    echo "Please provide resource group name:"
    read RESOURCE_GROUP_NAME
done


for ai_resource_name in $(az resource list -g $RESOURCE_GROUP_NAME --query "[?kind=='Hub']" | jq -r .[].name); do
    #echo "Found AI Resource":$ai_resource_name
    nic_resource_id=$(az network private-endpoint show --name "$ai_resource_name-pe-aistudio" --resource-group $RESOURCE_GROUP_NAME | jq -r .networkInterfaces[0].id)
    #echo "NetworkInterface Resource Id:" $nic_resource_id

    az network nic show --ids $nic_resource_id | jq -r '.ipConfigurations[] | .privateIPAddress as $ip | .privateLinkConnectionProperties.fqdns[] | "\($ip) \(.)"'
    HUB_IP=$(az network nic show --ids $nic_resource_id | jq --arg hubdns "$HUB_DNS_NAME" -r '.ipConfigurations[] | .privateIPAddress as $ip | .privateLinkConnectionProperties.fqdns[] | select(contains($hubdns)) | "\($ip)"')
    
    nic_resource_id=$(az network private-endpoint show --name "$ai_resource_name-pe-storageblob" --resource-group $RESOURCE_GROUP_NAME | jq -r .networkInterfaces[0].id)
    az network nic show --ids $nic_resource_id | jq -r '.ipConfigurations[] | .privateIPAddress as $ip | .privateLinkConnectionProperties.fqdns[] | "\($ip) \(.)"'
    
    nic_resource_id=$(az network private-endpoint show --name "$ai_resource_name-pe-storagefile" --resource-group $RESOURCE_GROUP_NAME | jq -r .networkInterfaces[0].id)
    az network nic show --ids $nic_resource_id | jq -r '.ipConfigurations[] | .privateIPAddress as $ip | .privateLinkConnectionProperties.fqdns[] | "\($ip) \(.)"'
done


for ai_project_name in $(az resource list -g $RESOURCE_GROUP_NAME --query "[?kind=='Project']" | jq -r .[].name); do
    workspaceid=$(az resource show -g $RESOURCE_GROUP_NAME -n $ai_project_name --resource-type Microsoft.MachineLearningServices/workspaces | jq -r '.properties.workspaceId')
    echo "$HUB_IP $workspaceid.$HUB_DNS_NAME"
    echo "$HUB_IP $workspaceid.workspace.westus.cert.api.azureml.ms"
done

