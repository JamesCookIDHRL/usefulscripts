#!/bin/bash
# Version 1.0 
# Copies the contents of the directory located at $1 to the directory located at $2
# Remember, if you have directory1 and directory2, with directory2 containing a previous copy of directory1, you must reference directory1 as the source and directory2 as the destination.

SOURCE=$1
DESTINATION=$2

rsync -avPH --append --delete --exclude '*.DS_Store' "${SOURCE}" "${DESTINATION}"
