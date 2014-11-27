#!/bin/sh

. ${SBase}/build_utils.sh
logMsg "Building the BASE Tool Chain"
if [ ${ROOT} != "/home/lfs" ] ; then
 logMsg "These scripts should run from /home/lfs folder"
 exit 1
fi
StageFile=${ROOT}/config/.scriptlist
TrackFile=${ROOT}/.baseTrack

if ! [ -f "$TrackFile" ]
then
logMsg "Creating the track file..."
echo 0 > $TrackFile
fi

echo "stageFile=$StageFile, TrackFile=$TrackFile"
seq_build $StageFile $TrackFile
#errorMsg $? "Failed Build at Base Tool Chain"
logMsg "So far the Base Tool Chain Compilation is  Success"
exit 0
