#!/bin/bash

apt-get update && apt-get install curl wget

MetalLB_RTAG=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')

echo "Metallb Tag: $MetalLB_RTAG"

if [ -z $MetalLB_RTAG ]; then
	echo "Metallb Tag not found, exiting"
	exit 1
fi

mkdir ~/metallb
cd ~/metallb

wget https://raw.githubusercontent.com/metallb/metallb/v$MetalLB_RTAG/config/manifests/metallb-native.yaml

if [ ! -s  metallb-native.yaml  ]; then
        echo "File metallb-native.yaml is empty, exiting"
        exit 1
fi

kubectl apply -f metallb-native.yaml
