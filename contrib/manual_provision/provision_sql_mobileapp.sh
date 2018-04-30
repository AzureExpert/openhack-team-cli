#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: provision_sql_mobileapp.sh -g <resourceGroupName> -l <resourceGroupLocation>" 1>&2; exit 1; }

declare resourceGroupName=""
declare resourceGroupLocation=""

# Variables
sqlServerName="mydrivingdbserver-$RANDOM"
sqlDBNAme="mydrivingDB"
mobileAppName="mydriving-$RANDOM"
hostingPlanName="mydrivingPlan-$RANDOM"
startip="0.0.0.0"
endip="255.255.255.255"
username="devopsopenhacksa"
sqlServerPassword=$(az keyvault secret show --vault-name devops-openhack-keyvault --name shared-sqlServerAdminPassword -o json|jq -r .value)

# Initialize parameters specified from command line
while getopts ":g:l:" arg; do
    case "${arg}" in
        g)
            resourceGroupName=${OPTARG}
        ;;
        l)
            resourceGroupLocation=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$resourceGroupName" ]]; then
    echo "This script will look for an existing resource group "
    echo "You can create new resource groups with the CLI using: az group create "
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$resourceGroupLocation" ]]; then
    echo "If creating a *new* resource group, you need to set a location "
    echo "You can lookup locations with the CLI using: az account list-locations "

    echo "Enter resource group location:"
    read resourceGroupLocation
fi


echo "$(tput setaf 3)Creating App Service plan...$(tput sgr 0)"
(
	set -x
	az appservice plan create --name $hostingPlanName --resource-group $resourceGroupName \
	--location $resourceGroupLocation
)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)App Service plan:" $hostingPlanName "created successfully...$(tput sgr 0)"
fi


echo "$(tput setaf 3)Creating web app...$(tput sgr 0)"
(
	set -x
	az webapp create --name $mobileAppName --plan $hostingPlanName --resource-group $resourceGroupName
)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)Web app:" $mobileAppName "created successfully...$(tput sgr 0)"
fi

echo "$(tput setaf 3)Creating SQL Server...$(tput sgr 0)"
(
	set -x
	az sql server create --name $sqlServerName --resource-group $resourceGroupName \
	--location $resourceGroupLocation --admin-user $username --admin-password $sqlServerPassword
)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)SQL Server:" $sqlServerName "created successfully...$(tput sgr 0)"
fi

echo "$(tput setaf 3)Setting firewall rules of SQL Server...$(tput sgr 0)"
(
	set -x
	az sql server firewall-rule create --server $sqlServerName --resource-group $resourceGroupName \
	--name AllowYourIp --start-ip-address $startip --end-ip-address $endip
)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)Firewall rules of SQL Server:" $sqlServerName "created successfully...$(tput sgr 0)"
fi


echo "$(tput setaf 3)Creating the database...$(tput sgr 0)"
(
	set -x
	az sql db create --server $sqlServerName --resource-group $resourceGroupName --name $sqlDBNAme \
	--service-objective S0 --collation 'SQL_Latin1_General_CP1_CI_AS'
)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)Database:" $sqlDBNAme "created successfully...$(tput sgr 0)"
fi

echo "$(tput setaf 3)Getting the connections string and assigning it to the app settings of the we app...$(tput sgr 0)"
(
	set -x
	connstring=$(az sql db show-connection-string --name $sqlDBNAme --server $sqlServerName \
	--client ado.net --output tsv)
	connstring=${connstring//<username>/$username}
	connstring=${connstring//<password>/$sqlServerPassword}
	az webapp config appsettings set --name $mobileAppName --resource-group $resourceGroupName \
	--settings "SQLSRV_CONNSTR=$connstring"

)

if [ $? == 0 ];
then
    echo "$(tput setaf 2)Connection string added to web app:" $mobileAppName " successfully...$(tput sgr 0)"
fi