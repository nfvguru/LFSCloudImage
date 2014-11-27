
. ${SBase}/build_utils.sh
logMsg "Building the LFS"
if [ ${ROOT} != "/" ] ; then
 logMsg "These scripts should run from /home/lfs folder"
 exit 1
fi
if [[ $EUID -ne 0 ]]; then
   logMsg "This script must be run as root" 
   exit 1
fi

StageFile=${ROOT}/config/.scriptLFSlist
TrackFile=${ROOT}/.lfsTrack

if ! [ -f "$TrackFile" ]
then
logMsg "Creating the track file..."
echo 0 > $TrackFile
fi

echo "stageFile=$StageFile, TrackFile=$TrackFile"
seq_build $StageFile $TrackFile
#errorMsg $? "Failed Build at Base Tool Chain"
logMsg "So far the LFS Tool Chain Compilation is  Success"
logMsg "Now Setting up BootScripts ..."
BootFiles=${ROOT}/config/.bootScripts
TrackFile=${ROOT}/.bootTrack
if ! [ -f "$TrackFile" ]
then
logMsg "Creating the track file..."
echo 0 > $TrackFile
fi
seq_build $BootFiles $TrackFile
logMsg "Boot Scripts updated  Successfully !!"
