#!/bin/bash

DIR_SRC=$1
DIR_DST=$2

function recursive_copy 
{
	local ZONE_PATH=$1

	if [ -f $DIR_SRC/$ZONE_PATH ]
	then
		if [ -n "`tail -n 1 $DIR_SRC/$ZONE_PATH`" ]
		then
			tail -n 1 $DIR_SRC/$ZONE_PATH > $DIR_DST/zoneinfo/$ZONE_PATH
		fi
	elif [ -d $DIR_SRC/$ZONE_PATH ]
	then
		mkdir -p $DIR_DST/zoneinfo/$ZONE_PATH
		for element in `ls $DIR_SRC/$ZONE_PATH`
		do
			recursive_copy $ZONE_PATH/$element
		done
	fi
}

# Copy all the timezone files; just keep the last line
 
if [ ! -e $DIR_DST/zoneinfo ]
then
	mkdir "$DIR_DST/zoneinfo"
fi

for zone in `ls $DIR_SRC`
do
	if [ -d $DIR_SRC/$zone ]
	then
		mkdir -p $DIR_DST/zoneinfo/$zone
		recursive_copy $zone
	elif [ -f $DIR_SRC/$zone ]
	then
		# Keep the standard timezones which are at the root of the archive
		for i in "CET" "CST6CDT" "EST" "EST5EDT" "GMT" "HST" "MST" "MST7DMT" "NZ" "PST8PDT" "ROC" "ROK" "UCT" "UTC" "WET" "W-SU" 
		do
			if [ $zone = $i ]
			then
				tail -n 1 $DIR_SRC/$zone > $DIR_DST/zoneinfo/$zone
			fi
		done
	fi
done

exit 0