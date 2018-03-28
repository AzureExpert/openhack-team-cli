#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: deploy_app_aks.sh -s <relative save location> -g <resourceGroupName>" 1>&2; exit 1; }

declare relativeSaveLocation=""
declare resourceGroupName=""

# Initialize parameters specified from command line
while getopts ":s:r:" arg; do
    case "${arg}" in
        s)
            relativeSaveLocation=${OPTARG}
        ;;
        g)
            resourceGroupName=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$relativeSaveLocation" ]]; then
    echo "Enter a source code path:"
    read relativeSaveLocation
    [[ "${relativeSaveLocation:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
    echo "Enter the resource group name:"
    read resourceGroupName
    [[ "${relativeSaveLocation:?}" ]]
fi

INGRESS_IP=$(kubectl get svc team-ingress-traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Get the name of the SQL server
sqlServer=$(az sql server list -g $resourceGroupName -o tsv --query [0].name)

# Add firewall rule to allow APIs to connect to SQL server database
az sql server firewall-rule create -n allow-k8s-ingress -g $resourceGroupName -s $sqlServer --start-ip-address $INGRESS_IP --end-ip-address $INGRESS_IP

echo -e "\n\nSQL Server Firewall rule added to allow $INGRESS_IP."

# Get the values to update the SQL Server secrets yaml file and create it on the cluster
sqlServerFQDN=$(az sql server list -g $resourceGroupName -o tsv --query [0].fullyQualifiedDomainName)
sqlPassword=$(az keyvault secret show --vault-name devops-openhack-keyvault --name sqlServerAdminPassword -o tsv --query value)

# TODO: replace the values in the secrets.yaml, base64 encode them, create the secret on the cluster