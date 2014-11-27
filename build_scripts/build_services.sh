#!/bin/sh

. ${SBase}/build_utils.sh
logMsg "Building Additional Packages"
StageFile=${ROOT}/config/.srvlist
TrackFile=${ROOT}/.srvTrack

if ! [ -f "$TrackFile" ]
then
logMsg "Creating the track file..."
echo 0 > $TrackFile
fi

echo "stageFile=$StageFile, TrackFile=$TrackFile"
seq_build $StageFile $TrackFile
errorMsg $? "Failed while building additional packages"
logMsg "Additional Packages are Compiled"
