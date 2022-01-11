#!/bin/bash
# Version 1.0
# This script creates a .iso installer file in the same directory as the installer application specified on the command line.
# Usage: ./macosiso.sh /path/to/Install\ macOS\ [name].app

LOCATION=$1
VERSION_NAME=${LOCATION##*Install }
VERSION_NAME=${VERSION_NAME%%.app*}
CREATEINSTALLMEDIA_EXISTS=0

removeTemporaryFile () {
	echo "Removing temporary file"
	if [ -d /tmp/"${VERSION_NAME}".iso.cdr ]; then
		rm -f /tmp/tmp/"${VERSION_NAME}".iso.cdr /tmp/"${VERSION_NAME}".sparseimage
	else
		rm -f /tmp/"${VERSION_NAME}".sparseimage
	fi
	if [ $? -ne 0 ]; then
		echo "Could not remove temporary file(s) in /tmp"
		exit 1
	fi
}

if [ -f "${LOCATION}"/Contents/Resources/createinstallmedia ]; then
	# createinstallmedia command is present
	echo "Creating temporary file"
	hdiutil create -o /tmp/"${VERSION_NAME}" -size 14G -layout SPUD -fs HFS+J -type SPARSE
	if [ $? -ne 0 ]; then
		echo "Creating sparsebundle failed"
		exit 1
	fi
	echo "Mounting the temporary file"
	HDI_OUTPUT=$(hdiutil attach /tmp/"${VERSION_NAME}".sparseimage -noverify -mountpoint /Volumes/install_build)
	if [ $? -ne 0 ]; then
		echo "Mounting failed"
		removeTemporaryFile
		exit 1
	fi
	DISK_IDENTIFIER=${HDI_OUTPUT%% *}
	echo "Using createinstallmedia command — sudo required"
	sudo "${LOCATION}"/Contents/Resources/createinstallmedia --volume /Volumes/install_build
	if [ $? -ne 0 ]; then
		echo "createinstallmedia command failed"
		hdiutil detach -force "${DISK_IDENTIFIER}"
	
		removeTemporaryFile
		exit 1
	fi
	echo "Unmounting temporary file"
	hdiutil detach -force /Volumes/Install\ "${VERSION_NAME}"/
	echo "Converting to .iso"
	hdiutil convert /tmp/"${VERSION_NAME}".sparseimage -format UDTO -o /tmp/"${VERSION_NAME}".iso
	if [ $? -ne 0 ]; then
		echo "hdiutil convert command failed"
		removeTemporaryFile
		exit 1
	fi
	echo "Changing file extension and moving to same directory as installer"
	mv /tmp/"${VERSION_NAME}".iso.cdr "${LOCATION}"/../"${VERSION_NAME}".iso
	removeTemporaryFile
	echo "Done."
else
	echo "createinstallmedia does not exist at the specified location. Please provide the correct path to the installer."
fi
