#!/bin/bash
set -eux

source $(dirname $0)/create-issue.sh

ISSUE_TITLE="Updatecli failed for multus ${MULTUS_VERSION}"
trap report-error EXIT INT

new_package=false
new_package36=false

# set_section_value FILE SECTION KEY OLD NEW
# Replace "KEY: OLD" with "KEY: NEW" only inside the top-level SECTION block
# of FILE, so identical tags used by other images are left untouched.
set_section_value() {
	sed -i -E "/^$2:/,/^[^[:space:]#]/ s/^([[:space:]]+$3: )$4\$/\1$5/" "$1"
}

bump_package() {
	if [ "$new_package" = false ]; then
		package_version=$(yq '.packageVersion' packages/rke2-multus/package.yaml)
		new_version=$(printf "%02d" $((10#$package_version + 1)))
		sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus/package.yaml
		new_package=true
	fi
}
if [ -n "$CNI_PLUGINS_VERSION" ]; then
	current_cni_plugins_version=$(yq '.cniplugins.image.tag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_cni_plugins_version" != "$CNI_PLUGINS_VERSION" ]; then
		echo "Updating CNI plugin version to $CNI_PLUGINS_VERSION"
		sed -i "s/$current_cni_plugins_version/$CNI_PLUGINS_VERSION/g" packages/rke2-multus/charts/values.yaml
		package_version=$(yq '.packageVersion' packages/rke2-multus/package.yaml)
		new_version=$(printf "%02d" $((10#$package_version + 1)))
		sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus/package.yaml
		new_package=true
	fi
        current_cni_plugins_version=$(yq '.cniplugins.image.tag' packages/rke2-multus-1.34-1.36/charts/values.yaml)
	if [ "$current_cni_plugins_version" != "$CNI_PLUGINS_VERSION" ]; then
		echo "Updating CNI plugin version to $CNI_PLUGINS_VERSION"
		sed -i "s/$current_cni_plugins_version/$CNI_PLUGINS_VERSION/g" packages/rke2-multus-1.34-1.36/charts/values.yaml
		package_version=$(yq '.packageVersion' packages/rke2-multus-1.34-1.36/package.yaml)
		new_version=$(printf "%02d" $((10#$package_version + 1)))
		sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus-1.34-1.36/package.yaml
		new_package36=true
	fi
fi
if [ -n "$NETWORK_CONTROLLER_VERSION" ]; then
	current_network_controller_version=$(yq '.dynamicNetworksController.image.primeTag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_network_controller_version" != "$NETWORK_CONTROLLER_VERSION" ]; then
		echo "Updating dynamic network controller version to $NETWORK_CONTROLLER_VERSION"
		set_section_value packages/rke2-multus/charts/values.yaml dynamicNetworksController primeTag "$current_network_controller_version" "$NETWORK_CONTROLLER_VERSION"
		bump_package
	fi
	current_network_controller_version=$(yq '.dynamicNetworksController.image.tag' packages/rke2-multus-1.34-1.36/charts/values.yaml)
	if [ "$current_network_controller_version" != "$NETWORK_CONTROLLER_VERSION" ]; then
		echo "Updating dynamic network controller version to $NETWORK_CONTROLLER_VERSION"
		sed -i "s/$current_network_controller_version/$NETWORK_CONTROLLER_VERSION/g" packages/rke2-multus-1.34-1.36/charts/values.yaml
		if [ "$new_package36" = false ]; then
			package_version=$(yq '.packageVersion' packages/rke2-multus-1.34-1.36/package.yaml)
			new_version=$(printf "%02d" $((10#$package_version + 1)))
			sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus-1.34-1.36/package.yaml
			new_package36=true
		fi
	fi
fi
if [ -n "$MIRRORED_NETWORK_CONTROLLER_VERSION" ]; then
	current_mirrored_network_controller_version=$(yq '.dynamicNetworksController.image.tag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_mirrored_network_controller_version" != "$MIRRORED_NETWORK_CONTROLLER_VERSION" ]; then
		echo "Updating mirrored dynamic network controller version to $MIRRORED_NETWORK_CONTROLLER_VERSION"
		set_section_value packages/rke2-multus/charts/values.yaml dynamicNetworksController tag "$current_mirrored_network_controller_version" "$MIRRORED_NETWORK_CONTROLLER_VERSION"
		bump_package
	fi
fi
if [ -n "$MULTI_NETWORKPOLICY_VERSION" ]; then
	current_mnp_version=$(yq '.multiNetworkPolicy.image.primeTag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_mnp_version" != "$MULTI_NETWORKPOLICY_VERSION" ]; then
		echo "Updating multi-networkpolicy-nftables version to $MULTI_NETWORKPOLICY_VERSION"
		set_section_value packages/rke2-multus/charts/values.yaml multiNetworkPolicy primeTag "$current_mnp_version" "$MULTI_NETWORKPOLICY_VERSION"
		bump_package
	fi
fi
if [ -n "$MIRRORED_MULTI_NETWORKPOLICY_VERSION" ]; then
	current_mirrored_mnp_version=$(yq '.multiNetworkPolicy.image.tag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_mirrored_mnp_version" != "$MIRRORED_MULTI_NETWORKPOLICY_VERSION" ]; then
		echo "Updating mirrored multi-networkpolicy-nftables version to $MIRRORED_MULTI_NETWORKPOLICY_VERSION"
		set_section_value packages/rke2-multus/charts/values.yaml multiNetworkPolicy tag "$current_mirrored_mnp_version" "$MIRRORED_MULTI_NETWORKPOLICY_VERSION"
		bump_package
	fi
fi
# Note: we use sed instead of yq to update the packageVersion field
# since yq insists on injecting the tag !!int in front of the value
# when the number is 08 or 09
if [ -n "$MULTUS_VERSION" ]; then
	app_version=$(echo "$MULTUS_VERSION" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+' | tr -d 'v')
	current_multus_version=$(yq '.image.tag' packages/rke2-multus/charts/values.yaml)
	current_app_version=$(echo "$current_multus_version" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+' | tr -d 'v')
	if [ "$current_multus_version" != "$MULTUS_VERSION" ]; then
		echo "Updating Multus chart to $MULTUS_VERSION"
		if [ "$app_version" != "$current_app_version" ]; then
			yq -i ".version = \"v$app_version\"" packages/rke2-multus/charts/Chart.yaml
			yq -i ".appVersion = \"$app_version\"" packages/rke2-multus/charts/Chart.yaml
			yq -i ".version = \"$app_version\"" packages/rke2-multus/templates/crd-template/Chart.yaml
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus/charts/values.yaml
			sed -i "s/packageVersion:.*/packageVersion: 01/g" packages/rke2-multus/package.yaml
		else
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus/charts/values.yaml
			if [ "$new_package" = false ]; then
				package_version=$(yq '.packageVersion' packages/rke2-multus/package.yaml)
				new_version=$(printf "%02d" $((10#$package_version + 1)))
				sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus/package.yaml
			fi
		fi
	fi
	current_multus_version=$(yq '.image.tag' packages/rke2-multus-1.34-1.36/charts/values.yaml)
	current_app_version=$(echo "$current_multus_version" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+' | tr -d 'v')
	if [ "$current_multus_version" != "$MULTUS_VERSION" ]; then
		echo "Updating Multus chart to $MULTUS_VERSION"
		if [ "$app_version" != "$current_app_version" ]; then
			yq -i ".version = \"v$app_version\"" packages/rke2-multus-1.34-1.36/charts/Chart.yaml
			yq -i ".appVersion = \"$app_version\"" packages/rke2-multus-1.34-1.36/charts/Chart.yaml
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus-1.34-1.36/charts/values.yaml
			sed -i "s/packageVersion:.*/packageVersion: 01/g" packages/rke2-multus-1.34-1.36/package.yaml
		else
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus-1.34-1.36/charts/values.yaml
			if [ "$new_package36" = false ]; then
				package_version=$(yq '.packageVersion' packages/rke2-multus-1.34-1.36/package.yaml)
				new_version=$(printf "%02d" $((10#$package_version + 1)))
				sed -i "s/packageVersion:.*/packageVersion: $new_version/g" packages/rke2-multus-1.34-1.36/package.yaml
			fi
		fi
	fi
fi
