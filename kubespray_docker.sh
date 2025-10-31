#!/bin/bash

KUBESPRAY_VERSION="v2.23.0"

docker run --rm -it --mount type=bind,source=/$HOME/kubespray/inventory/mycluster/,dst=/inventory  --mount type=bind,source="${HOME}"/.ssh/id_rsa,dst=/root/.ssh/id_rsa -v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK quay.io/kubespray/kubespray:${KUBESPRAY_VERSION} bash
