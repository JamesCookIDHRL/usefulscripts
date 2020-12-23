#!/bin/bash
# Name: directoryhash.sh
# Version: 1.0
# Description: Calculates a value representing the hash of a directory, optionally depending on the structure of the directory and the files within.

# Explain usage of command.
printCommandUsage() {
	echo "directoryhash.sh: Calculates a value representing the hash of a directory."
		echo -e "USAGE: directoryhash.sh [-h] [-a] [-A] [-e] [-s] [-H \033[4mhashing algorithm\033[00m ] <-d /path/to/directorytohash>"
		echo ""
		echo "Options are as follows:"
		echo "  -h			Display this help and exit. [If this option is selected, it will take precedence over any other options.]"
		echo "  -a			Consider all files, including hidden files, within visible directories."
		echo "  -A			Consider all directories, including hidden directories, and visible files."
		echo "  -e			Consider all files and directories, regardless of whether they are hidden. Equivalent to the -a and -A options together."
		echo "  -s			Only consider the structure of the directory and its subdirectories, and ignore the contents of the files contained within. Note that the -a option is ignored if this option is specified."
		echo "  -H			Choose the hashing algorithm that the script uses. Currently supported options are: SHA-1 (default), SHA-224, SHA-256, SHA-384 or SHA-512."
		echo ""
}

# Initialise variables.
REQUESTHELP=0
CONSIDERALLFILES=0
CONSIDERALLDIRECTORIES=0
DIRECTORYSPECIFIED=0
DIRECTORYTOHASH=""
VERIFYSTRUCTURE=0
HASHINGALGORITHM=1
CURRENTDATETIME=$(date '+%d%m%Y%H%M%S')

while getopts ":d:H:haAset" opt; do
	case $opt in
		d)
			DIRECTORYSPECIFIED=1
			DIRECTORYTOHASH=$OPTARG
			;;
		H)
			if [ $OPTARG == "SHA-1" ]; then
				HASHINGALGORITHM=1
			elif [ $OPTARG == "SHA-224" ]; then
				HASHINGALGORITHM=2
			elif [ $OPTARG == "SHA-256" ]; then
				HASHINGALGORITHM=3
			elif [ $OPTARG == "SHA-384" ]; then
				HASHINGALGORITHM=4
			elif [ $OPTARG == "SHA-512" ]; then
				HASHINGALGORITHM=5
			else
				HASHINGALGORITHM=0
			fi
			;;
		h)
			REQUESTHELP=1
			;;
		a)
			CONSIDERALLFILES=1
			;;
		A)
			CONSIDERALLDIRECTORIES=1
			;;
		s)
			VERIFYSTRUCTURE=1
			;;
		e)
			CONSIDERALLFILES=1
			CONSIDERALLDIRECTORIES=1
			;;
		\?)
			echo "Invalid option: -$OPTARG"
			exit
			;;
		*)
			echo "Option -$OPTARG requires an argument."
			exit
			;;
	esac
done

# Determine if the command line arguments specified are sufficient for program to run.
if [ $# == 0 ]; then
	# No arguments, so go straight to printCommandUsage.
	printCommandUsage
	exit
else
	# Check if help has been requested, if so then display help then halt script.
	if [ $REQUESTHELP = 1 ]; then
		printCommandUsage
		exit
	fi
	# Check directory has been specified, if not then halt script.
	if [ $DIRECTORYSPECIFIED != 1 ]; then
		echo "No directory was specified. Please see the help for more information."
		exit
	fi
	# Check directory specified is valid.
	if [ ! -d "${DIRECTORYTOHASH}" ]; then
		echo "${DIRECTORYTOHASH}"
		echo "The location you have specified does not exist, or is not a directory. Please try again with a valid directory."
		exit
	fi
	# Check hashing algorithm is valid.
	if [ $HASHINGALGORITHM == 0 ]; then
		echo "The hashing algorithm you have specified does not exist, or is not currently supported. Please see the help for more information."
		exit
	fi
fi

# Prepare directory for temporary files.
RANDOMNUMBER=$RANDOM
HASHEDLOCATION=$(echo -n $DIRECTORYTOHASH | shasum | awk '{ print $1 }' )
TMPDIRECTORY=$CURRENTDATETIME$RANDOMNUMBER$HASHEDLOCATION
mkdir /tmp/${TMPDIRECTORY}
OIFS=$IFS
IFS=$'\n'

# Change directory into the directory to hash. This ensures that if two directories are identical but stored in different locations, they will result in the same hash.
CURRENTDIRECTORY=$(pwd)
cd $DIRECTORYTOHASH

# List contents of directory, and store output in a variable.
if [ $CONSIDERALLFILES == 1 ]; then
	if [ $CONSIDERALLDIRECTORIES == 1 ]; then
		# All files and folders.
		find . | sort > /tmp/${TMPDIRECTORY}/contentlist
	else
		# All files and non-hidden folders.
		find . -not -path '*/\.*/*' -not -type d | sort > /tmp/${TMPDIRECTORY}/contentlist
	fi
else
	if [ $CONSIDERALLDIRECTORIES == 1 ]; then
		# All folders and non-hidden files.
		find . -not -name '*\.*' | sort > /tmp/${TMPDIRECTORY}/contentlist
	else
		# All non-hidden files and non-hidden folders.
		find . -not -path '*/\.*' | sort > /tmp/${TMPDIRECTORY}/contentlist
	fi
fi

# Read the contentlist file and separate it out into directories and files.
while IFS= read -r LINE
do
	if [ -d "${LINE}" ]; then
		echo "${LINE}" >> /tmp/${TMPDIRECTORY}/directorylist
	else
		echo "${LINE}" >> /tmp/${TMPDIRECTORY}/filelist
	fi
done < /tmp/${TMPDIRECTORY}/contentlist

# Copy the directorylist file to the tohash file.
cp /tmp/${TMPDIRECTORY}/directorylist /tmp/${TMPDIRECTORY}/tohash
if [ $VERIFYSTRUCTURE == 1 ]; then
	# We've been instructed to just verify the structure, so hash the tohash file as it is.
	if [ $HASHINGALGORITHM == 1 ]; then
		shasum /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 2 ]; then
		shasum -a 224 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 3 ]; then
		shasum -a 256 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 4 ]; then
		shasum -a 384 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 5 ]; then
		shasum -a 512 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	fi
else
	# We need to verify the files as well, so we'll add their hashes to the tohash file.
	if [ $HASHINGALGORITHM == 1 ]; then
		# Hash files with SHA-1, append result to the tohash temporary file.
		while IFS= read -r LINE
		do
			shasum $LINE >> /tmp/${TMPDIRECTORY}/tohash
		done < /tmp/${TMPDIRECTORY}/filelist
		# Print hash of tohash file to terminal.
		shasum /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 2 ]; then
		# Hash files with SHA-224, append result to the tohash temporary file.
		while IFS= read -r LINE
		do
			shasum -a 224 $LINE >> /tmp/${TMPDIRECTORY}/tohash
		done < /tmp/${TMPDIRECTORY}/filelist
		# Print hash of tohash file to terminal.
		shasum -a 224 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 3 ]; then
		# Hash files with SHA-256, append result to the tohash temporary file.
		while IFS= read -r LINE
		do
			shasum -a 256 $LINE >> /tmp/${TMPDIRECTORY}/tohash
		done < /tmp/${TMPDIRECTORY}/filelist
		# Print hash of tohash file to terminal.
		shasum -a 256 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 4 ]; then
		# Hash files with SHA-384, append result to the tohash temporary file.
		while IFS= read -r LINE
		do
			shasum -a 384 $LINE >> /tmp/${TMPDIRECTORY}/tohash
		done < /tmp/${TMPDIRECTORY}/filelist
		# Print hash of tohash file to terminal.
		shasum -a 384 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	elif [ $HASHINGALGORITHM == 5 ]; then
		# Hash files with SHA-512, append result to the tohash temporary file.
		while IFS= read -r LINE
		do
			shasum -a 512 $LINE >> /tmp/${TMPDIRECTORY}/tohash
		done < /tmp/${TMPDIRECTORY}/filelist
		# Print hash of tohash file to terminal.
		shasum -a 512 /tmp/${TMPDIRECTORY}/tohash | awk '{ print $1 }'
	fi
fi

# Remove temporary files.
rm -r /tmp/${TMPDIRECTORY}

# Reset IFS Settings.
IFS=$OIFS

# Change back to original directory.
cd $CURRENTDIRECTORY
