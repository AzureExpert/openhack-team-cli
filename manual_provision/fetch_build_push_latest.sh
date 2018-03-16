#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
#script requires latest version of .netcore to be installed ()

usage() { echo "Usage: fetch_build_push_latest.sh -b <build flavor> -r <resourceGroupName>  -t <image tag> -u <githubRepository> -s <relative save location>" 1>&2; exit 1; }

declare buildFlavor=""
declare resourceGroupName=""
declare imageTag=""
declare githubRepository=""
declare relativeSaveLocation=""

# Initialize parameters specified from command line
while getopts ":b:r:t:u:s:" arg; do
    case "${arg}" in
        b)
            buildFlavor=${OPTARG}
        ;;
        r)
            resourceGroupName=${OPTARG}
        ;;
        t)
            imageTag=${OPTARG}
        ;;
        u)
            githubRepository=${OPTARG}
        ;;
        s)
            relativeSaveLocation=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$buildFlavor" ]]; then
    echo "Enter a build flavor (Debug, Release)"
    read buildFlavor
    [[ "${buildFlavor:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
    echo "This script will look for an existing resource group, otherwise a new one will be created "
    echo "You can create new resource groups with the CLI using: az group create "
    echo "Enter a resource group name"
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$imageTag" ]]; then
    echo "This script requires name and optionally a tag in the 'name:tag' format"
    echo "Enter an image tag "
    read imageTag
    [[ "${imageTag:?}" ]]
fi

if [[ -z "$githubRepository" ]]; then
    echo "Enter the github url (ssh/https) from which to clone the application source:"
    echo "NOTE: if https, the repository needs to be public."
    read githubRepository
fi

if [[ -z "$relativeSaveLocation" ]]; then
    echo "Path relative to script in which to download and build the app"
    echo "Enter an relative path to save location "
    read relativeSaveLocation
    [[ "${relativeSaveLocation:?}" ]]
fi

if [ -z "$buildFlavor" ] || [ -z "$resourceGroupName" ] || [ -z "$imageTag" ] || [ -z "$githubRepository" ] || [ -z "$relativeSaveLocation" ]; then
    echo "Either one of buildFlavor, resourceGroupName, imageTag, githubRepository, or relativeSaveLocation is empty"
    usage
fi

#DEBUG
echo $buildFlavor
echo $resourceGroupName
echo $imageTag
echo $githubRepository
echo $relativeSaveLocation
echo ''

ACR=`az acr list -g $resourceGroupName --query "[].{acrName:name}" --output json | jq .[].acrName | sed 's/\"//g'`

#login to ACR
az acr login --name $ACR

#get the acr repsotiory id to tag image with.
ACR_ID=`az acr list -g $resourceGroupName --query "[].{acrLoginServer:loginServer}" --output json | jq .[].acrLoginServer | sed 's/\"//g'`

echo "ACR ID: "$ACR_ID

TAG=$ACR_ID"/"$imageTag

echo "TAG: "$TAG

rm -rf $relativeSaveLocation

mkdir $relativeSaveLocation

pushd $relativeSaveLocation;

#clone the repository
git clone $githubRepository 1> /dev/null

pushd ./openhack-devops


pushd ./src/MobileAppServiceV2/MyDriving.POIService.v2

dotnet build -c $buildFlavor

docker build . -t $TAG 

docker push $TAG

popd 

popd

rm -rf $relativeSaveLocation

popd


