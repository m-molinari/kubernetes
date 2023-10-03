#!/bin/bash
#

CURL=`which curl`

if [ -z "$CURL" ]; then
	apt-get install curl
fi

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
