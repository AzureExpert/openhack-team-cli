# OpenHack-CLI

CLI tool `oh` to provision more that one resources on Azure in parallel

`docker run -it -e AZURE_CLIENT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
     -e AZURE_CLIENT_SECRET=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
     -e AZURE_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
     -e AZURE_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
     julienstroheker/oh --help`

## Features

Current commands supported :

* Resource Group
* SPN
* AKS

## Getting Started

### Prerequisites

### Quickstart / Contribution
(Add steps to get up and running quickly)

1. `go get github.com/Azure-Samples/openhack-team-cli`
2. Fork that repository into your GitHub account
3. Add your repository as a remote for $GOPATH/github.com/Azure/openhack-team-cli
4. Create a new working branch (git checkout -b feat/my-feature) and do your work on that branch.
5. When you are ready for us to review, push your branch to GitHub, and then open a new pull request with us.

#### Code Structure

The code for the project is organized as follows:

* The individual programs are located in cmd/. Code inside of cmd/ is not designed for library re-use.
* Shared libraries are stored in pkg/.
* The tests/ directory contains a number of utility scripts. Most of these are used by the CI/CD pipeline. [TODO]
* The docs/ folder is used for documentation and examples. [TODO]

#### Manual Provisioning

1. Change to the `./contrib/manual_provision/` directory
1. Replace the values and then execute the following script:

```bash
./setup.sh -i <subscriptionId> -l <resourceGroupLocation> -n <teamName>
```