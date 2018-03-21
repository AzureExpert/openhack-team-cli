#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: setup.sh -i <subscriptionId> -g <resourceGroupName> -r <registryName> -c <clusterName> -l <resourceGroupLocation> -n <teamName>" 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupName=""
declare registryName=""
declare clusterName=""
declare resourceGroupLocation=""
declare teamName=""

# Initialize parameters specified from command line
while getopts ":i:g:r:c:l:n:" arg; do
    case "${arg}" in
        i)
            subscriptionId=${OPTARG}
        ;;
        g)
            resourceGroupName=${OPTARG}
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

if [[ -z "$resourceGroupName" ]]; then
    echo "This script will look for an existing resource group, otherwise a new one will be created "
    echo "You can create new resource groups with the CLI using: az group create "
    echo "Enter a resource group name"
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
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

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$registryName" ] || [ -z "$clusterName" ] || [ -z "$resourceGroupLocation" ] || [ -z "$teamName" ]; then
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

set +e

#Check for existing RG
if [ `az group exists -n $resourceGroupName` == false ]; then
    echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
    set -e
    (
        set -x
        az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
    )
else
    echo "Using existing resource group..."
fi

# bash ./provision_acr.sh -i $subscriptionId -g $resourceGroupName -r $registryName -l $resourceGroupLocation
# bash ./provision_aks.sh -i $subscriptionId -g $resourceGroupName -c $clusterName -l $resourceGroupLocation
# bash ./provision_aks_acr_auth.sh -i $subscriptionId -g $resourceGroupName -c $clusterName -r $registryName -l $resourceGroupLocation
bash ./fetch_build_push_latest.sh -b Release -r $resourceGroupName -t $teamName":latest" -u git@github.com:Azure-Samples/openhack-devops.git -s ~/test_fetch_build
bash ./deploy_app_aks.sh