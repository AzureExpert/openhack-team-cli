#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: deploy_apps_acr.sh  -r <registryName> -c <containerName>" 1>&2; exit 1; }

#-i <subscriptionId> -g <resourceGroupName> -c <clusterName> -l <resourceGroupLocation>
declare registryName=""
declare containerName=""

# Initialize parameters specified from command line
while getopts ":r:c:" arg; do
    case "${arg}" in
        r)
            registryName=${OPTARG}
        ;;
        c)
            containerName=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$registryName" ]]; then
    echo "Enter a name for the Azure Container Registry you want to connect:"
    read registryName
fi

if [[ -z "$containerName" ]]; then
    echo "Enter a name for the Container:"
    read containerName
fi

az acr login --name $registryName

echo "Pushing " $containerName " to " $registryName " ..."
(
    docker push $containerName
)

