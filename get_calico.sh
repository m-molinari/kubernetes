#!/bin/bash
#

VER=$1

if [ -z $VER ] ; then
	echo "pass version as argument"
	exit 1
fi

#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v${VER}/manifests/calico.yaml -o calico.yaml && kubectl apply -f calico.yaml



