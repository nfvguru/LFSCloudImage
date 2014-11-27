##################################################

errorMsg () {
  rc=$1
  Msg="$2"
  if [ $rc != 0 ] ; then
    logMsg "$Msg"
    exit $rc
  fi
}

logMsg () {
        echo -e "$1" | tee -a $LFile $DFile
}

##################################################
seq_build ()  {
	scriptList=$1
	trackfile=$2
	echo "LFS=$LFS"
	SDir=${LFS}/sources
	cd ${SDir}
	echo "Doing Sequencial Build using $scriptList"
	count=0
	track=`cat $trackfile`
	#echo "track=$track"
	for entry in `cat $scriptList`; 
	do
		cd ${SDir}
		scriptFile=`echo $entry | cut -d'|' -f1`
		count=`expr $count + 1`
		echo "count=$count, track=$track"
		if [ $count -le $track ]; then
		  logMsg "Skipping already completed $scriptFile"
		  continue;
		fi
		logMsg "======================================="
		logMsg "Build using $scriptFile"
		sh ${SBase}/${scriptFile} $SBase ${SDir} $DFile
		errorMsg $? "Failed to Compile $scriptFile"
		logMsg "The $scriptFile completed successfully..."
		logMsg "======================================="
		echo $count > $trackfile
	done
#	exit 0
}

copy_system () {
	copyList=$1
	target=$2
	logMsg "Copying system using $copyList to $target "
	for entry in `cat $copyList`; 
	do
	   #logMsg "copying $entry"
	   #Get the folder name
	   pathname=`dirname $entry`
	   # Make sure the target folder is created, if not exits
	   mkdir -pv ${target}${pathname} 2>&1 >> ${DFile}
	   #copy the file to target
	   cp -dpRvf ${entry} ${target}${pathname} 2>&1 >> ${DFile}
	done
}

make_busybox_links() {
    	bb_toolsList=$1
	prefix=$2
	logMsg "creating tools using busybox"
	for entry in `cat $bb_toolsList`;
        do
	   ln -sv /bin/busybox ${prefix}/$entry
	done
}
