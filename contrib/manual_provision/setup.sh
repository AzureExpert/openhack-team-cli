#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: setup.sh -i <subscriptionId> -g <resourceGroupTeam> -s <resourceGroupShared> -r <registryName> -c <clusterName> -l <resourceGroupLocation> -n <teamName>" 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupTeam=""
declare resourceGroupShared=""
declare registryName=""
declare clusterName=""
declare resourceGroupLocation=""
declare teamName=""

# Initialize parameters specified from command line
while getopts ":i:g:s:r:c:l:n:" arg; do
    case "${arg}" in
        i)
            subscriptionId=${OPTARG}
        ;;
        g)
            resourceGroupTeam=${OPTARG}
        ;;
        s)
            resourceGroupShared=${OPTARG}
        ;;
        r)
            registryName=${OPTARG}
        ;;
        c)
            clusterName=${OPTARG}
        ;;
        l)
            resourceGroupLocation=${OPTARG}
        ;;
        n)
            teamName=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$subscriptionId" ]]; then
    echo "Your subscription ID can be looked up with the CLI using: az account show --out json "
    echo "Enter your subscription ID:"
    read subscriptionId
    [[ "${subscriptionId:?}" ]]
fi

if [[ -z "$resourceGroupTeam" ]]; then
    echo "This script will look for an existing resource group, otherwise a new one will be created "
    echo "You can create new resource groups with the CLI using: az group create "
    echo "Enter a resource group name"
    read resourceGroupTeam
    [[ "${resourceGroupTeam:?}" ]]
fi

if [[ -z "$resourceGroupShared" ]]; then
    echo "This is the name of the resourcegrouo for the shared infrastructure"
    echo "Enter a resource group name"
    read resourceGroupShared
    [[ "${resourceGroupShared:?}" ]]
fi

if [[ -z "$registryName" ]]; then
    echo "Enter a name for the Azure Container Registry you want to create:"
    read registryName
fi

if [[ -z "$clusterName" ]]; then
    echo "Enter a name for the Azure Kubernetes Service (AKS) you want to create:"
    read clusterName
fi

if [[ -z "$resourceGroupLocation" ]]; then
    echo "If creating a *new* resource group, you need to set a location "
    echo "You can lookup locations with the CLI using: az account list-locations "

    echo "Enter resource group location:"
    read resourceGroupLocation
fi

if [[ -z "$teamName" ]]; then
    echo "Enter a team name to be used in app provisioning:"
    read teamName
fi

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupTeam" ] || [ -z "$registryName" ] || [ -z "$clusterName" ] || [ -z "$resourceGroupLocation" ] || [ -z "$teamName" ]; then
    echo "Parameter missing..."
    usage
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
    az login
fi

#set the default subscription id
az account set --subscription $subscriptionId

#TODO need to check if provider is registered and if so don't run this command.  Also probably need to sleep a few minutes for this to finish.
az provider register -n Microsoft.ContainerService

set +e

#Check for existing RG
if [ `az group exists -n $resourceGroupTeam` == false ]; then
    echo "Resource group with name" $resourceGroupTeam "could not be found. Creating new resource group.."
    set -e
    (
        set -x
        az group create --name $resourceGroupTeam --location $resourceGroupLocation 1> /dev/null
    )
else
    echo "Using existing resource group..."
fi

bash ./provision_acr.sh -i $subscriptionId -g $resourceGroupTeam -r $registryName -l $resourceGroupLocation
bash ./provision_aks.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -l $resourceGroupLocation
bash ./provision_aks_acr_auth.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -r $registryName -l $resourceGroupLocation
bash ./git_fetch.sh -u git@github.com:Azure-Samples/openhack-devops.git -s ./test_fetch_build
bash ./deploy_ingress_dns.sh -s ./test_fetch_build -l $resourceGroupLocation -n $teamName
bash ./configure_sql.sh -s ./test_fetch_build -g $resourceGroupShared -n $teamName -u YourUserName

# Save the public DNS address to be provisioned in the helm charts for each service
dnsURL='akstraefik'$teamName'.'$resourceGroupLocation'.cloudapp.azure.com'
bash ./build_deploy_poi.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-poi' -d $dnsURL -n $teamName
bash ./build_deploy_user.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-user' -d $dnsURL -n $teamName
bash ./build_deploy_trip.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-trip' -d $dnsURL -n $teamName