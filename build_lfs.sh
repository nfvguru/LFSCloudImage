#!/bin/bash
start_time=`date +%s`
source config/.BUILD
echo -e "\033[33m ----- BUILD OPTIONS --------------\033[35m"
echo -e "CONFIG=$CONFIG\nSETUP=$SETUP\nBASE=$BASE\nLCO=$LCO\nKERNEL=$KERNEL\nPKG=$PKG\nINITRD=$INITRD\nCLOUD=$CLOUD\nSERVICES=$SERVICES\nIMAGE=$IMAGE"
echo -e "\033[33m------------------------------------\n\033[0m"

if [ $CONFIG -eq 1 ] ; then
	sleep 1
	echo -e "[ C O N F I G        : ]\c"
	echo -e "\033[32m\t\t\t\tOK\033[0m"
	CONFIG=1
fi
if [ $SETUP -eq 1 ] ; then
	sleep 1
	echo -e "[ S E T U P          : ]\c"
	bash localscripts/setupenv.sh 
	SETUP=1

fi
if [ $BASE -eq 1 ]  ; then
	sleep 1
	export LFS=/mnt/lfs
	echo -e "[ B A S E            : ]\c"
	bash localscripts/startbase.sh
	BASE=1
fi
lfsmounted=$(mount | grep -c sda3)
if [ $lfsmounted -eq  0 ]; then
	mount /dev/sda3 /mnt/lfs
	export LFS=/mnt/lfs
	mount -v --bind /dev $LFS/dev
	mount -vt devpts devpts $LFS/dev/pts
	mount -vt proc proc $LFS/proc
	mount -vt sysfs sysfs $LFS/sys
	if [ -h $LFS/dev/shm ]; then
	  link=$(readlink $LFS/dev/shm)
	  mkdir -p $LFS/$link
	  mount -vt tmpfs shm $LFS/$link
	  unset link
	else
	  mount -vt tmpfs shm $LFS/dev/shm
	fi
fi
if [ $LCO -eq 1 ] ; then
	sleep 1
	echo -e "[ L F S              : ]\c"
	LCO=1
	chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash -c "make lfstoolchain"  2>&1 >/dev/null

    if [ ! -f third ]; then
	chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash -c "/build_scripts/tools/fstab"  2>&1 >/dev/null

	chroot $LFS /tools/bin/env -i \
    HOME=/root TERM=$TERM PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /tools/bin/find /{,usr/}{bin,lib,sbin} -type f \
  -exec /tools/bin/strip --strip-debug '{}' ';' 2>/dev/null
	echo 1 > third
    fi
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi
if [ $KERNEL -eq 1 ] ; then
	sleep 1
	echo -e "[ K E R N E L        : ]\c"

	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "make kernel"  2>&1 >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
	KERNEL=1
fi
if [ $PKG -eq 1 ] ; then
	sleep 1
	echo -e "[ P K G              : ]\c"
	PKG=1
	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "make packages"  2>&1 >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi
if [ $INITRD -eq 1 ] ; then
	sleep 1
	echo -e "[ I N I T R D        : ]\c"
	INITRD=1
    if [ ! -f fourth ]; then
	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "build_scripts/initrd/mkinittools.sh"  2>&1 >/dev/null
	echo 1 > fourth
    fi

	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "make initrd"  2>&1 >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi
if [ $CLOUD -eq 1 ] ; then
	sleep 1
	echo -e "[ C L O U D          : ]\c"
	CLOUD=0
	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "/build/makecloudport"  2>&1 >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi

if [ $SERVICES -eq 1 ] ; then
	sleep 1
	echo -e "[ S E R V I C E S    : ]\c"
	SERVICES=1
	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "make services"  2>&1 >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi

if [ $IMAGE -eq 1 ] ; then
	sleep 1
	echo -e "[ I M A G E          : ]\c"
	sh localscripts/setupimage.sh
	chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash -c "/makeimage.sh" 2>&1  >/dev/null
	echo -e "\033[32m\t\t\t\tOK\033[0m"
fi

echo -e "CONFIG=$CONFIG\nSETUP=$SETUP\nBASE=$BASE\nLCO=$LCO\nKERNEL=$KERNEL\nINITRD=$INITRD\nPKG=$PKG\nCLOUD=$CLOUD\nSERVICES=$SERVICES\nIMAGE=$IMAGE\n" > config/.BUILD
end_time=`date +%s`
echo "==> Completed in `expr $end_time  - $start_time` seconds <=="
