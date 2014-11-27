#!/bin/sh
# HARD CODED PARAMS for the timebeing.
# TODO: read from a config file
IMG_SIZE=$((500 * 1028 * 1024)) #500MB
BUILD_DIR=/build
IMG_NAME=nfvo_test.img
version=$(cat .version)
echo "$(expr $version + 1)" > .version
QCOW2_IMG=lfs_i386_$(date +%d_%h)_4.0.$(cat .version).qcow2
CopyList=${ROOT}/.copyList
IMG=/mnt/myimg
INITRD=/build/initrd-1.img
BUSYLINKS=/.bbToolsMain
CopyList=/config/.copyList

. ${SBase}/build_utils.sh
logMsg "Building the Image"

start_time=`date +%s`

# Move to the build dir
cd ${BUILD_DIR}
# Do some howsekeeping
rm -rvf ${IMG_NAME} 2>&1 >> ${DFile}
rm -rvf ${QCOW2_IMG} 2>&1 >> ${DFile}

################# HARD DISK GEOMETRY #####
# bytes per sector
bytes=512
# sectors per track
sectors=63
# heads per track
heads=255
# bytes per cylinder is bytes*sectors*head
bpc=$(( bytes*sectors*heads ))
# number of cylinders
cylinders=$(($IMG_SIZE/$bpc))
# rebound the size
img_size=$(( ($cylinders+1)*$bpc ))
logMsg "bpc=$bpc, img_size=$img_size"

#create the image
qemu-img create -f raw ${IMG_NAME} $img_size

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
# We don't have any modules yet. So no need to copy System map 
# for the time-being.
#cp /boot/System.map-3.8.1 /mnt/myimg/boot/System.map-1

#Copy initrd
#ToDO: Need to reduce the initrd image size.
cp $INITRD /mnt/myimg/boot/initrd-1.img

#Get the UUID
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
echo    "    append initrd=/boot/initrd-1.img root=UUID=$myUUID init=/sbin/init1 quiet rw" >> ${IMG}/boot/extlinux.conf

# Just print the extlinux config , to debug, if any :)
cat ${IMG}/boot/extlinux.conf

#Now copy the LFS system

#Create essential Dirs
mkdir -pv ${IMG}/{root,usr,dev,proc,sys,run,var/run,var/log,tmp,dev/pts} 2>&1 >> ${DFile}

###################################################################################
#     										  #		
#   TODO: nee to make the below things wokring                                    #
#   For a Real Tiny Image using busybox                                           #
#                                                                                 #
#Copy Busybox to support the basic tools                                          # 
# mkdir -pv ${IMG}/{bin,sbin,lib}                                                 #
#cp -dpRvf /bin/busybox ${IMG}/bin                                                #
#chmod +x ${IMG}/bin/busybox                                                      #
#                                                                                 #
#Create sym links to busy for the essential tools                                 #
#make_busybox_links ${BUSYLINKS} ${IMG}                                           #
#                                                                                 #
#Copy System                                                                      # 
#copy_system  ${CopyList} ${IMG}                                                  #
###################################################################################

#Copy the System Files
cp -dpRf /bin ${IMG}
cp -dpRf /lib ${IMG}
cp -dpRf /etc ${IMG}
#cp -dpvRf /lib/{firmware,kbd,lsb,modules,services,udev} ${IMG}/lib 2>&1 >> ${DFile}
cp -dpRf /sbin ${IMG}
mkdir -pv ${IMG}/usr/lib
cp -dpRf /usr/lib/lib* ${IMG}/usr/lib
cp -dpRf /usr/lib/gnupg ${IMG}/usr/lib
cp -dpRf /usr/lib/perl5 ${IMG}/usr/lib
cp -dpRf /usr/lib/sudo ${IMG}/usr/lib
cp -dpRf /usr/lib/python2.7 ${IMG}/usr/lib
cp -dpRf /usr/lib/gcc ${IMG}/usr/lib
cp -dpRf /usr/include ${IMG}/usr/
cp -dpRf /usr/lib/crti.o ${IMG}/usr/lib
cp -dpRf /usr/lib/crtn.o ${IMG}/usr/lib
cp -dpRf /usr/lib/node_modules ${IMG}/usr/lib
cp -dpRf /usr/lib/ruby ${IMG}/usr/lib
mkdir -pv ${IMG}/usr/lib/terminfo/l/
mkdir -pv ${IMG}/usr/share/terminfo/l/
cp -dpRf /usr/share/terminfo/l/linux  ${IMG}/usr/share/terminfo/l/
cp -dpRf /usr/lib/terminfo/l/linux ${IMG}/usr/lib/terminfo/l/

#Copy BootScripts
cp -dpRf /build_scripts/tools/rc.local.boot ${IMG}/etc/rc.d/init.d/rc.local
cp -dpRf /build_scripts/tools/rc.local ${IMG}/etc
#cp -dpRf /build_scripts/tools/getCert.sh ${IMG}/etc
mkdir -p  ${IMG}/usr/bin
cp -dpRf /build_scripts/tools/register ${IMG}/usr/bin

#Copy Upstart Scripts
mkdir -p ${IMG}/etc/init
cp -dpRf /sources/upstart/* ${IMG}/etc/init

#copy Some more Bins using copylist
copy_system  ${CopyList} ${IMG}                                                  

#add DPKG
mkdir -pv ${IMG}/usr
cp -dpRf /usr/sbin ${IMG}/usr
cp -dpRf /usr/bin ${IMG}/usr
cp -Rvf /usr/dpkg ${IMG}/usr 2>&1 >> ${DFile}
ln -sv /usr/dpkg/bin/dpkg ${IMG}/bin/dpkg 2>&1 >> ${DFile}
ln -sv /usr/dpkg/bin/dpkg-deb ${IMG}/bin/dpkg-deb 2>&1 >> ${DFile}
#cp /usr/dpkg/var/lib/dpkg/status ${IMG}/usr/dpkg/var/lib/dpkg/
#touch ${IMG}/usr/dpkg/var/lib/dpkg/status
touch ${IMG}/usr/dpkg/var/lib/dpkg/available
#errorMsg $? "Failed to copy System"
#sleep 1
# Use busybox for some of the tools not available now
chmod +x ${IMG}/bin/busybox
ln -sv /bin/busybox ${IMG}/bin/wget

#copy cloudport for testing
#cp /build/cloudport5.4.deb ${IMG}

# Create the Console
mkdir -pv ${IMG}/dev 2>&1 >> ${DFile}
cd ${IMG}/dev
mknod -m 0600 console c 5 1
cd -


COPY Debians to Install
mkdir -pv ${IMG}/usr/debs
#cp /build/openvpn-2.3.4.deb ${IMG}/usr/debs
#cp /build/cloudport5.4.deb ${IMG}/usr/debs
##cp /sources/apt_0.6.46.4-0.1_i386.deb ${IMG}/usr/debs
##cp /sources/debian-archive-keyring_2007.02.19_all.deb ${IMG}/usr/debs
mkdir -pv ${IMG}/usr/debs
#cp /sources/cloud-init-0.7.5.tar.gz ${IMG}/usr/debs
cp /sources/cloud-init-0.6.3.tar.gz ${IMG}/usr/debs
cp /sources/cloud-init-0.6.3.patch ${IMG}/usr/debs
cp /sources/cloud-utils_0.25.orig.tar.gz ${IMG}/usr/debs
#cp /sources/heat-cfntools-1.2.7.tar.gz ${IMG}/usr/debs
cp /sources/heat-cfntools-1.2.6.tar.gz ${IMG}/usr/debs
cp /sources/setuptools-2.1.tar.gz ${IMG}/usr/debs
cp /sources/pbr-0.5.23.tar.gz ${IMG}/usr/debs
cp /sources/pip-1.5.6.tar.gz ${IMG}/usr/debs
cp /sources/pyyaml_3.10.orig.tar.gz ${IMG}/usr/debs

#Test upstart
cp /build/targetX.tar.gz ${IMG}/usr/debs
#Missing Python Libs
cp /sources/cheetah_2.4.4.orig.tar.gz ${IMG}/usr/debs
cp /sources/distribute_0.6.24.orig.tar.gz ${IMG}/usr/debs
#cp /sources/unittest2_0.5.1.orig.tar.gz ${IMG}/usr/debs
cp /sources/python-oauth_1.0.1.orig.tar.gz ${IMG}/usr/debs
cp /sources/configobj_4.7.2+ds.orig.tar.gz ${IMG}/usr/debs

#Modified Cloud-Init config
cp /sources/cloud.cfg ${IMG}/usr/debs

#Now install the Debians
#chroot "$LFS" /usr/bin/env -i \
#    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
#    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
#    /bin/bash --login
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" dpkg -i /usr/debs/debian-archive-keyring_2007.02.19_all.deb 2>&1 >> ${DFile}
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" dpkg -i /usr/debs/apt_0.6.46.4-0.1_i386.deb 2>&1 >> ${DFile}
#copy the apt-get config & create essential folders
mkdir -pv ${IMG}/var/lib
cd ${IMG}/var/lib
ln -s /usr/dpkg/var/lib/dpkg dpkg
cd -
cd  ${IMG}/usr/dpkg/bin
ln -s /usr/bin/gpgv gpgv
cd -
mkdir ${IMG}/var/dpkg
#cp ${IMG}/usr/share/doc/apt/examples/sources.list ${IMG}/etc/apt/
##cp /usr/dpkg/sources.list ${IMG}/etc/apt/
##cp /usr/dpkg/newlava.conf ${IMG}/etc/apt/apt.conf
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
##apt-key adv --keyserver  hkp://keyserver.ubuntu.com:80 --recv-keys 8B48AD6246925553
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
##apt-key adv --keyserver  hkp://keyserver.ubuntu.com:80 --recv-keys 6FB2A1C265FFB764
#chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6FB2A1C265FFB764
#chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
#gpg --keyserver blackhole.pca.dfn.de --recv-key 8B48AD6246925553
##rm -rvf ${IMG}/var/lib/apt/lists/
##mkdir -pv ${IMG}/var/lib/apt/lists/partial
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" apt-get clean 
#chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" apt-get update
#COPY THE files , not update now
##cp -dpRf /var/lib/apt/lists/* ${IMG}/var/lib/apt/lists/

#WORKAROUND TO AVOID circular dependancy for debconf
#mkdir -p ${IMG}/usr/share/perl5/
#cp -dpRf /build/DEBCONF/usr/share/perl5/Debconf ${IMG}/usr/share/perl5/
#chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin"  \
#PERL5LIB="/usr/share/perl5" \
#dpkg -i /var/cache/apt/archives/debconf*

#chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
#apt-get -t wheezy-backports -f install debconf -y

#COPY THE files, don't download from net
##mkdir -pv ${IMG}/var/cache/apt/archives/
##cp -drRf /var/cache/apt/archives/* ${IMG}/var/cache/apt/archives/
##chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
##apt-get -t wheezy-backports -f install --no-download cloud-init cloud-utils cloud-initramfs-growroot -y
#apt-get -t wheezy-backports -f install debconf -y


#NOW install setuptools, cloud-init, heat-cfntools
mkdir -pv  ${IMG}/opt/setuptools/lib/python2.7/site-packages/
chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
/bin/cloudinstall



# NOW THE CLEANUP
chroot ${IMG} /usr/bin/env -i PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/dpkg/bin:/usr/dpkg/sbin" \
/bin/cleaninstall del

#Now detatch and umount partitions
losetup -d $loopdevMBR
umount ${IMG}
losetup -d $loopdev
logMsg "Converting to QCOW2........"
qemu-img convert -f raw -O qcow2 $IMG_NAME $QCOW2_IMG
end_time=`date +%s`
logMsg "==> Completed in `expr $end_time  - $start_time` seconds <=="
logMsg "Image ( /build/${QCOW2_IMG} ) Created Successfully....."

