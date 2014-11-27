
#!/bin/sh
. ${SBase}/build_utils.sh
logMsg "Building Linux Kernel"
SDir=${LFS}/sources
BDir=configbackup
logMsg "Sdir=$SDir"
logMsg "Dfile=$DFile"

cd ${SDir}
start_time=`date +%s`
FirstRun=0
basename=linux-3.8.1
if [ \! -d "${basename}" ]; then
   logMsg "Need to Extract the Source"
   tar -Jxf ${basename}.tar.xz 2>&1 >> ${DFile}
   errorMsg $? "Failed to untar Linux: ${basename}.tar.xz"
   FirstRun=1
fi
cd ${basename}
if [ $FirstRun -eq 1 ]; then
   make mrproper 2>&1 >> ${DFile}
   errorMsg $? "Failed on make mrproper "
fi

mkdir -pv ${BDir}
# Create backup of the existing config
cp -vf .config ${BDir}/Config-${start_time} 2>&1 >> ${DFile}
cp -vf ${SDir}/config-3.8.1 .config 2>&1 >> ${DFile}
make oldconfig 2>&1 >> ${DFile}
errorMsg $? "Failed on make oldconfig "
make 2>&1 >> ${DFile}
errorMsg $? "Failed on make "
make modules_install 2>&1 >> ${DFile}
errorMsg $? "Failed on make modules install "
cp -v arch/x86/boot/bzImage /boot/vmlinuz-3.8.1-lfs-7.3 2>&1 >> ${DFile}
cp -v System.map /boot/System.map-3.8.1 2>&1 >> ${DFile}
cp -v .config /boot/config-3.8.1 2>&1 >> ${DFile}


end_time=`date +%s`
logMsg "==> Completed in `expr $end_time  - $start_time` seconds <=="
