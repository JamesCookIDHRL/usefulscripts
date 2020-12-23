#!/bin/bash
# Version 1.0
# Creates a macOS install disk out of a volume at $2, using the Installer located at $1

LOCATION=$1
VOLUME=$2


sudo "${LOCATION}"/Contents/Resources/createinstallmedia --volume "${VOLUME}" --nointeraction #--applicationpath "${LOCATION}"
