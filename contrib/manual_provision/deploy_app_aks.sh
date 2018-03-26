#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: deploy_app_aks.sh -s <relative save location>" 1>&2; exit 1; }

declare relativeSaveLocation=""

# Initialize parameters specified from command line
while getopts ":s:" arg; do
    case "${arg}" in
        s)
            relativeSaveLocation=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$relativeSaveLocation" ]]; then
    echo "Enter a source code path:"
    read relativeSaveLocation
    [[ "${relativeSaveLocation:?}" ]]
fi

echo "helm init --upgrade ..."

helm init --upgrade

# Add a loop to wait after the tiller installation
# Ex : Kubectl get pods --all-namespaces -> tiller-*************** - Creating... Deployed

# You can override the values from the values.yaml using the --set cmd
# https://github.com/Azure-Samples/openhack-devops/blob/add_helm/src/MobileAppServiceV2/MyDriving.POIService.v2/helm/values.yaml

# Make sure you have the hosts CNAME entry in your DNS provider

echo "helm install ..."
helm install $relativeSaveLocation "/openhack-devops/src/MobileAppServiceV2/MyDriving.POIService.v2/helm" --name getpois 
#--set ingress.hosts=mydriving-admin.julien.work,image.repository=julienstroheker.azurecr.io/myapp,image.tag=v34,ingress.path="/api/GetAllPOIs"