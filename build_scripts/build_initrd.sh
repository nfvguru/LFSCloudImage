#!/bin/sh
#
#
# G L O B A L S 

INITFS=/build/initfs
INITSCRIPTS=${SBase}/initrd
INIT_IN_USE=${INITSCRIPTS}/init.sh
INITRD=/build/initrd-1.img
BBTOOLS=/.bbToolsList
BBLIBS=/.bbLibsList

KERNEL=3.8.1


. ${SBase}/build_utils.sh
logMsg "Building Initrd"
start_time=`date +%s`

# Housekeeping
rm -Rvf ${INITFS} 2>&1 >> ${DFile}
rm -Rvf ${INITRD} 2>&1 >> ${DFile}


######################################################################
#   WORKAROUND SOLUTION :  USE BUILT_IN mkinitramfs
#   TODO: we need our own script to minimise the footprint
######################################################################
cd /build
/sbin/mkinitramfs $KERNEL 2>&1 >> ${DFile}
cp -dpv initrd.img-${KERNEL} ${INITRD} 2>&1 >> ${DFile}
cd -
end_time=`date +%s`
logMsg "==> Completed in `expr $end_time  - $start_time` seconds <=="
#errorMsg $? "Failed Build at Base Tool Chain"
logMsg "Initial Ramdisk (${INITRD}) is Created Successfully"
exit 0
###################################################################3
#	Exiting .... As Workaround is done.
# 
####################################################################


# Create the root directory for INIT RAM DISK
mkdir -pv ${INITFS} 2>&1 >> ${DFile}

#Change to the initfs root dir
cd ${INITFS} 

#Populate the Dir Structure
mkdir -pv {bin,sys,dev,proc,etc,lib,run} 2>&1 >> ${DFile}

#Copy Busybox ( dynamically linked for the timebeing)
#cp -dpvf /bin/busybox ${INITFS}/bin 2>&1 >> ${DFile}

#Copy Essential Links
copy_system  ${BBLIBS} ${INITFS}

#Create some sym-links to get the BusyBox working
pushd ${INITFS}/bin 2>&1 >> ${DFile}
make_busybox_links ${BBTOOLS}
#ln -s busybox ps
#ln -s busybox dmesg
popd 2>&1 >> ${DFile}


#Create the Device Nodes
mknod dev/console c 5 1 
mknod dev/ram0 b 1 1
mknod dev/null c 1 3
mknod dev/tty1 c 4 1
mknod dev/tty2 c 4 2

# Make sbin as a link to bin
ln -s bin sbin

# Copy the init script
cp -dpvf ${INIT_IN_USE} ${INITFS}/init 2>&1 >> ${DFile}
chmod +x ${INITFS}/init
#cp -dpvf ${INITFS}/init ${INITFS}/sbin 2>&1 >> ${DFile}
#cp -dpvf ${INITFS}/init ${INITFS}/linuxrc 2>&1 >> ${DFile}

# Everything Ready, Just create our Initrd
find . | cpio -o -H newc | gzip > ${INITRD}

end_time=`date +%s`
logMsg "==> Completed in `expr $end_time  - $start_time` seconds <=="
#errorMsg $? "Failed Build at Base Tool Chain"
logMsg "Initial Ramdisk (${INITRD}) is Created Successfully"
