#!/bin/bash
set -eu

source $(dirname $0)/create-issue.sh

ISSUE_TITLE="Updatecli failed for coredns ${COREDNS_VERSION}" 
trap report-error EXIT INT

if [ -n "$COREDNS_VERSION" ]; then
	coredns_url=$(yq '.url' packages/rke2-coredns/package.yaml)
	current_coredns_version=$(awk -F'/coredns-|.tgz' '{print $2}' <<< $coredns_url)
	if [ "$current_coredns_version" != "$COREDNS_VERSION" ]; then
		echo "Updating Coredns chart to $COREDNS_VERSION"
		yq -i ".url = \"https://github.com/coredns/helm/releases/download/coredns-${COREDNS_VERSION}/coredns-${COREDNS_VERSION}.tgz\" |
			.packageVersion = 00" packages/rke2-coredns/package.yaml
		GOCACHE='/home/runner/.cache/go-build' GOPATH='/home/runner/go' PACKAGE='rke2-coredns' make prepare
		find packages/rke2-coredns/charts -name '*.orig' -delete
		GOCACHE='/home/runner/.cache/go-build' GOPATH='/home/runner/go' PACKAGE='rke2-coredns' make patch
		make clean
	fi
fi
