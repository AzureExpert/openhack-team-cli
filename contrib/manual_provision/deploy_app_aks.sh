#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: deploy_app_aks.sh -s <relative save location>  -r <registryName>" 1>&2; exit 1; }

declare relativeSaveLocation=""
declare registryName=""
declare imageTag=""

# Initialize parameters specified from command line
while getopts ":s:r:" arg; do
    case "${arg}" in
        s)
            relativeSaveLocation=${OPTARG}
        ;;
        r)
            registryName=${OPTARG}
        ;;
        t)
            imageTag=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$relativeSaveLocation" ]]; then
    echo "Enter a source code path:"
    read relativeSaveLocation
    [[ "${relativeSaveLocation:?}" ]]
fi

if [[ -z "$registryName" ]]; then
    echo "Enter the registry name:"
    read registryName
    [[ "${relativeSaveLocation:?}" ]]
fi

echo "helm init --upgrade ..."

helm init --upgrade

tiller=$(kubectl get pods --all-namespaces | grep tiller | awk '{print $4}')

echo "Waiting for tiller ..."

while [ $tiller != "Running" ]; do
        echo "Waiting for tiller ..."
        tiller=$(kubectl get pods --all-namespaces | grep tiller | awk '{print $4}')
        sleep 5
done
echo "helm install ... from: " 
echo $relativeSaveLocation"/openhack-devops/src/MobileAppServiceV2/MyDriving.POIService.v2/helm"
echo "Registry: " $registryName 
# You can override the values from the values.yaml using the --set cmd
# https://github.com/Azure-Samples/openhack-devops/blob/add_helm/src/MobileAppServiceV2/MyDriving.POIService.v2/helm/values.yaml

# TODO: sed replace the value for the ingress hostname before deploying the chart

helm install $relativeSaveLocation"/openhack-devops/src/MobileAppServiceV2/MyDriving.POIService.v2/helm" --name api-pois --set image.repository=$registryName/apipois

# TODO: helm install the User and Trip APIs