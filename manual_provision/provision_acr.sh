if [ -z "$1" ]
  then
    echo "provision.sh [Registry Name] [Resource Group] [Location]"
fi
 


registryName = $1
myResourceGroup = $2 
location = $3


az group create --name $myResourceGroup --location $location
az acr create --resource-group $myResourceGroup --name $registryName --sku Basic

