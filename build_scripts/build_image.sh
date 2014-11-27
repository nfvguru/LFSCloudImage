#!/bin/sh
# 
# HARD CODED PARAMS for the timebeing.
# TODO: read from a config file
BUILD_DIR=/build
IMG_NAME=nfvo_test.img
IMG_SIZE=51200 # 51200 KB ~= 51MB (including patriont table, usable size nearly 49MB)
CopyList=${ROOT}/.copyList
TARGET=/build/tmproot
IMG=/mnt/myimg
INITRD=/build/initrd-1.img

. ${SBase}/build_utils.sh
logMsg "Building the Image"

start_time=`date +%s`

# Move to the build dir
cd ${BUILD_DIR}
# Do some howsekeeping
rm -rvf ${IMG_NAME} 2>&1 >> ${DFile}

#create the Disk File
dd if=/dev/zero of=${IMG_NAME} bs=1kB count=${IMG_SIZE} 2>&1 >> ${DFile}

#partioning TODO: make the below working.
#parted -s ${IMG_NAME} mklabel msdos
#parted -s ${IMG_NAME} mkpart primary ext2 0% 100%
#parted -s ${IMG_NAME} set 1 boot on

# Work around
loopdev=`losetup -f`
losetup $loopdev  ${IMG_NAME}
echo -e "n\np\n1\n\n\na\n1\nw\n" | fdisk $loopdev 
sleep 1
sec_start=`fdisk -l -u $loopdev | tail -1 | awk -F" " '{print $3}'`
blocks=`fdisk -l -u $loopdev | tail -1 | awk -F" " '{print $5}'`
logMsg "sector start=$sec_start, Blocks=$blocks"

#now detach the loop device
losetup -d $loopdev

#Calculate the partition table offset
p_offset=`expr $sec_start \* 512`
logMsg "p_offset=$p_offset"


#Reattach the image at the offset
#Find which loop device is avaialble
loopdev=`losetup -f`
logMsg "Attaching the image on $loopdev at offset $p_offset"
losetup -o $p_offset $loopdev ${IMG_NAME}

#Create Filesytem
mkfs.ext2 -b 1024 $loopdev 2>&1 >> ${DFile}

#ensure that the build point is available
mkdir -p $IMG

#mount the filesyste
mount $loopdev ${IMG}

#create the boot folder
mkdir  ${IMG}/boot

#Attch the MBR & Partition Table
loopdevMBR=`losetup -f`
losetup $loopdevMBR  ${IMG_NAME} -o 0  --sizelimit $p_offset

#Setup the MBR with extlinux
dd if=/dev/zero of=$loopdevMBR bs=446 count=1 2>&1 >> ${DFile}
dd if=/usr/share/syslinux/mbr.bin of=$loopdevMBR 2>&1 >> ${DFile}
/sbin/extlinux --install ${IMG}/boot 2>&1 >> ${DFile}
/sbin/extlinux --heads 255 --sectors 63 --install ${IMG}/boot 2>&1 >> ${DFile}

#Copy the Kernel and Related Files
cp /boot/vmlinuz-3.8.1-lfs-7.3 /mnt/myimg/boot/vmlinux-1
cp /boot/System.map-3.8.1 /mnt/myimg/boot/System.map-1

#Copy initrd
cp $INITRD /mnt/myimg/boot/initrd-1.img
#cp ${BUILD_DIR}/vmlinuz.badri /mnt/myimg/boot/vmlinux-1
#cp ${BUILD_DIR}/vmlinuz.lava /mnt/myimg/boot/vmlinux-1
tmpUUID=`blkid | grep $loopdev| awk -F" " '{print $2}'| awk -F"UUID=" '{print $2}'`
myUUID=`echo $tmpUUID | awk -F"\"" '{print $2}'`
logMsg ">>>>>>>>>>>>>>>>>>>>>>>>>>  $tmpUUID,$myUUID"

#Create the extlinux Configuration
cat > ${IMG}/boot/extlinux.conf << "EOF"
default NFVO 
timeout 30

label NFVO
    kernel /boot/vmlinux-1
EOF
echo	"    append initrd=/boot/initrd-1.img root=UUID=$myUUID quiet rw" >> ${IMG}/boot/extlinux.conf 

cat ${IMG}/boot/extlinux.conf

#Now copy the LFS system 
# ToDO: list out the files 
#copy_system  ${CopyList} ${IMG}
mkdir -p /mnt/myimg/sys
mkdir -p /mnt/myimg/dev
mkdir -p /mnt/myimg/proc
mkdir -p /mnt/myimg/run
mkdir -p /mnt/myimg/var/run
mkdir -p /mnt/myimg/var/log
mkdir -p /mnt/myimg/tmp
mkdir -p /mnt/myimg/dev/pts
cp -dpRf /bin /mnt/myimg/
cp -dpRf /lib /mnt/myimg/
cp -dpRf /etc /mnt/myimg/
cp -dpRf /sbin /mnt/myimg/
errorMsg $? "Failed to copy System"
sleep 1
chmod +x ${IMG}/bin/busybox

# Create the Console
mkdir -pv ${IMG}/dev 2>&1 >> ${DFile}
cd ${IMG}/dev
mknod -m 0600 console c 5 1
cd -

#Now detatch and umount partitions
losetup -d $loopdevMBR
umount ${IMG}
losetup -d $loopdev

end_time=`date +%s`
logMsg "==> Completed in `expr $end_time  - $start_time` seconds <=="
logMsg "Image ( /build/${IMG_NAME} ) Created Successfully....."
