#!/bin/bash

# Shane Faulkner
# http://shanefaulkner.com
# You are free to modify and distribute this code,
# so long as you keep my name and URL in it.
# Lots of thanks go out to TeamBAMF

#-------------------ROMS To Be Built------------------#

PRODUCT[0]="$1"			# phone model name (product folder name)
LUNCHCMD[0]="bamf_nexus-userdebug"	# lunch command used for ROM
BUILDNME[0]="bamf_nexus"		# name of the output ROM in the out folder, before "-ota-"
OUTPUTNME[0]="bamf_nexus-toro"		# what you want the new name to be

#---------------------Build Settings------------------#

# should they be moved out of the output folder
# like a dropbox or other cloud storage folder
# or any other folder you want
# also required for FTP upload
MOVE=y

# folder they should be moved to
STORAGE=~/android/zips

# your build source code directory path
SAUCE=~/android/$2

# number for the -j parameter
J=9

# generate an MD5
MD5=y

# sync repositories
SYNC=y

# run make clean first
CLEAN=y

# leave alone
DATE=`eval date +%m`-`eval date +%d`

#----------------------FTP Settings--------------------#

# set "FTP=y" if you want to enable FTP uploading
# must have moving to storage folder enabled first
FTP=n

# FTP server settings
FTPHOST[0]="razor-rom.com"	# ftp hostname
FTPUSER[0]="eoghan1@razor-rom.com"	# ftp username 
FTPPASS[0]="Vgv*T31&"	# ftp password
FTPDIR[0]="$1"	# ftp upload directory

#---------------------Build Bot Code-------------------#

echo -n "Moving to source directory..."
cd $SAUCE
echo "done!"

if [ $SYNC = "y" ]; then
	echo -n "Running repo sync..."
	repo sync
	echo "done!"
fi

if [ $CLEAN = "y" ]; then
	echo -n "Running make clean..."
	make clean
	echo "done!"
fi

for VAL in "${!PRODUCT[@]}"
do
	echo -n "Starting build..."
	source build/envsetup.sh && lunch ${LUNCHCMD[$VAL]} && time make -j$J otapackage
	echo "done!"

	if [ $MD5 = "y" ]; then
		echo -n "Generating MD5..."
		md5sum $SAUCE/out/target/product/${PRODUCT[$VAL]}/${BUILDNME[$VAL]}"-ota-"$DATE".zip" | sed 's|'$SAUCE'/out/target/product/'${PRODUCT[$VAL]}'/||g' > $SAUCE/out/target/product/${PRODUCT[$VAL]}/${BUILDNME[$VAL]}"-ota-"$DATE".md5sum.txt"
		echo "done!"
	fi

	if  [ $MOVE = "y" ]; then
		echo -n "Moving to cloud storage directory..."
		cp $SAUCE/out/target/product/${PRODUCT[$VAL]}/${BUILDNME[$VAL]}"-ota-"$DATE".zip" $STORAGE/${OUTPUTNME[$VAL]}"-"$DATE".zip"
		if [ $MD5 = "y" ]; then
			cp $SAUCE/out/target/product/toro/${BUILDNME[$VAL]}"-ota-"$DATE".md5sum.txt" $STORAGE/${OUTPUTNME[$VAL]}"-ota-"$DATE".md5sum.txt"
		fi
		echo "done!"
	fi

done

#----------------------FTP Upload Code--------------------#

if  [ $FTP = "y" ]; then
	echo "Initiating FTP connection..."

	cd $STORAGE
	ATTACHROM=`for file in *"-"$DATE".zip"; do echo -n -e "put ${file}\n"; done`
	if [ $MD5 = "y" ]; then
		ATTACHMD5=`for file in *"-"$DATE".md5sum.txt"; do echo -n -e "put ${file}\n"; done`
		ATTACH=$ATTACHROM"/n"$ATTACHMD5
	else
		ATTACH=$ATTACHROM
	fi

for VAL in "${!FTPHOST[@]}"
do
	echo -e "\nConnecting to ${FTPHOST[$VAL]} with user ${FTPUSER[$VAL]}..."
	ftp -nv <<EOF
	open ${FTPHOST[$VAL]}
	user ${FTPUSER[$VAL]} ${FTPPASS[$VAL]}
	tick
	cd ${FTPDIR[$VAL]}
	$ATTACH
	quit
EOF
done

	echo -e  "FTP transfer complete! \n"
fi

echo "All done!"
