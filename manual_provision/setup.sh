#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

bash ./provision_acr.sh -i 0c3a2f71-4128-4509-8719-3b16f291ad5f -g rgtest -r rgacr123 -l centralus
bash ./provision_aks.sh -i 0c3a2f71-4128-4509-8719-3b16f291ad5f -g rgtest -c rgaks123 -l centralus
bash ./provision_aks_acr_auth.sh -i 0c3a2f71-4128-4509-8719-3b16f291ad5f -g rgtest -c rgaks123 -r rgacr123 -l centralus
bash ./fetch_build_latest.sh -b Release -r rgtest -t test:latest -u git@github.com:Azure-Samples/openhack-devops.git -s ~/test_fetch_build
bash ./deploy_app_aks.sh