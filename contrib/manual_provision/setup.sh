#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: setup.sh -i <subscriptionId> -l <resourceGroupLocation> -n <teamName> " 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupLocation=""
declare teamName=""
declare keyVaultName=""

# Initialize parameters specified from command line
while getopts ":i:t:s:r:c:l:n:k:" arg; do
    case "${arg}" in
        i)
            subscriptionId=${OPTARG}
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

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupLocation" ] || [ -z "$teamName" ] ; then
    echo "Parameter missing..."
    usage
fi

randomChar() {
    s=abcdefghijklmnopqrstuvxwyz0123456789
    p=$(( $RANDOM % 36))
    echo -n ${s:$p:1}
}

declare random4Chars="$(randomChar;randomChar;randomChar;randomChar;)"
declare resourceGroupTeam="${teamName}rg${random4Chars}";
declare registryName="${teamName}acr${random4Chars}"
declare clusterName="${teamName}aks${random4Chars}"
declare keyVaultName="${teamName}"kv${random4Chars}

echo "=========================================="
echo " VARIABLES"
echo "=========================================="
echo "subscriptionId            = "${subscriptionId}
echo "resourceGroupLocation     = "${resourceGroupLocation}
echo "teamName                  = "${teamName}
echo "keyVaultName              = "${keyVaultName}
echo "random4Chars              = "${random4Chars}
echo "resourceGroupTeam         = "${resourceGroupTeam}
echo "registryName              = "${registryName}
echo "clusterName               = "${clusterName}
echo "=========================================="

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
    az login
fi

#set the default subscription id
echo "Setting subscription to $subscriptionId..."

az account set --subscription $subscriptionId

#TODO need to check if provider is registered and if so don't run this command.  Also probably need to sleep a few minutes for this to finish.
echo "Registering ContainerServiceProvider..."
az provider register -n Microsoft.ContainerService

set +e

#Check for existing RG
if [ `az group exists -n $resourceGroupTeam` == false ]; then
    echo "Resource group with name" $resourceGroupTeam "could not be found. Creating new resource group.."
    set -e
    (
        set -x
        az group create --name $resourceGroupTeam --location $resourceGroupLocation
    )
else
    echo "Using existing resource group..."
fi

echo "0-Provision KeyVault  (bash ./provision_kv.sh -i $subscriptionId -g $resourceGroupTeam -r $keyVaultName -l $resourceGroupLocation)"
bash ./provision_kv.sh -i $subscriptionId -g $resourceGroupTeam -k $keyVaultName -l $resourceGroupLocation

echo "1-Provision ACR  (bash ./provision_acr.sh -i $subscriptionId -g $resourceGroupTeam -r $registryName -l $resourceGroupLocation)"
bash ./provision_acr.sh -i $subscriptionId -g $resourceGroupTeam -r $registryName -l $resourceGroupLocation

echo "2-Provision AKS  (bash ./provision_aks.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -l $resourceGroupLocation)"
bash ./provision_aks.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -l $resourceGroupLocation

echo "3-Set AKS/ACR permissions  (bash ./provision_aks_acr_auth.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -r $registryName -l $resourceGroupLocation)"
bash ./provision_aks_acr_auth.sh -i $subscriptionId -g $resourceGroupTeam -c $clusterName -r $registryName -l $resourceGroupLocation

echo "4-Clone repo"
bash ./git_fetch.sh -u git@github.com:Azure-Samples/openhack-devops.git -s ./test_fetch_build

echo "5-Deploy ingress  (bash ./deploy_ingress_dns.sh -s ./test_fetch_build -l $resourceGroupLocation -n ${teamName}${random4Chars})"
bash ./deploy_ingress_dns.sh -s ./test_fetch_build -l $resourceGroupLocation -n ${teamName}${random4Chars}

echo "6-Configure SQL  (bash ./configure_sql.sh -s ./test_fetch_build -g $resourceGroupShared -u YourUserName -n ${teamName}${random4Chars} -k ${keyVaultName})"
bash ./configure_sql.sh -s ./test_fetch_build -g $resourceGroupShared -u YourUserName -n ${teamName}${random4Chars} -k ${keyVaultName}

# Save the public DNS address to be provisioned in the helm charts for each service
dnsURL='akstraefik'${teamName}${random4Chars}'.'$resourceGroupLocation'.cloudapp.azure.com'
echo -e "DNS URL for "${teamName}" is:\n"$dnsURL 

# echo "7-Build and deploy POI API to AKS  (bash ./build_deploy_poi.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-poi' -d $dnsURL -n ${teamName}${random4Chars})"
# bash ./build_deploy_poi.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-poi' -d $dnsURL -n ${teamName}${random4Chars}

# echo "8-Build and deploy User API to AKS  (bash ./build_deploy_user.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-user' -d $dnsURL -n ${teamName}${random4Chars})"
# bash ./build_deploy_user.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-user' -d $dnsURL -n ${teamName}${random4Chars}

# echo "9-Build and deploy Trip API to AKS  (# bash ./build_deploy_trip.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-trip' -d $dnsURL -n ${teamName}${random4Chars})"
# bash ./build_deploy_trip.sh -s ./test_fetch_build -b Release -r $resourceGroupTeam -t 'api-trip' -d $dnsURL -n ${teamName}${random4Chars}

echo "10- Clean the working environment"
bash ./cleanup_environment.sh -t ${teamName}
