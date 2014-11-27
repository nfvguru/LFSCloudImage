#!/bin/sh

if [ ! -f lfsdone ]; then

su - lfs -c /home/lfs/dobasebuild 2>&1 >> /dev/null
export LFS=/mnt/lfs
strip --strip-debug /tools/lib/* 2>/dev/null
strip --strip-unneeded /tools/{,s}bin/* 2>/dev/null
rm -rf /tools/{,share}/{info,man,doc} 2>&1 >> /dev/null
chown -R root:root $LFS/tools 2>&1 >> /dev/null
cp -dpRf /mnt/lfs/tools /home/build 2>&1 >> /dev/null
mkdir -v $LFS/{dev,proc,sys} 2>&1 >> /dev/null
mknod -m 600 $LFS/dev/console c 5 1 2>&1 >> /dev/null
mknod -m 666 $LFS/dev/null c 1 3 2>&1 >> /dev/null
mount -v --bind /dev $LFS/dev 2>&1 >> /dev/null
mount -vt devpts devpts $LFS/dev/pts 2>&1 >> /dev/null
mount -vt proc proc $LFS/proc 2>&1 >> /dev/null
mount -vt sysfs sysfs $LFS/sys 2>&1 >> /dev/null
if [ -h $LFS/dev/shm ]; then 
  link=$(readlink $LFS/dev/shm)
  mkdir -p $LFS/$link 
  mount -vt tmpfs shm $LFS/$link 2>&1 >> /dev/null
  unset link
else
  mount -vt tmpfs shm $LFS/dev/shm 2>&1 >> /dev/null
fi

#cd /home/build/nfvo/nfvolfs
cp -dpRvf config $LFS 2>&1 >> /dev/null
cp -dpRvf build_scripts $LFS 2>&1 >> /dev/null
cp -dpRvf build $LFS 2>&1 >> /dev/null
cp -dpRvf Makefile $LFS 2>&1 >> /dev/null
mkdir -pv $LFS/Logs 2>&1 >> /dev/null

cat > $LFS/prelfs.sh << "EOF"
#!/bin/bash
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib,mnt,opt,run} 2>&1 >> /dev/null
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var} 2>&1 >> /dev/null
install -dv -m 0750 /root 2>&1 >> /dev/null
install -dv -m 1777 /tmp /var/tmp 2>&1 >> /dev/null
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src} 2>&1 >> /dev/null
mkdir -pv /usr/{,local/}share/{doc,info,locale,man} 2>&1 >> /dev/null
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo} 2>&1 >> /dev/null
mkdir -pv /usr/{,local/}share/man/man{1..8} 2>&1 >> /dev/null
for dir in /usr /usr/local; do 
  ln -sv share/{man,doc,info} $dir 2>&1 >> /dev/null
done
case $(uname -m) in
 x86_64) ln -sv lib /lib64 && ln -sv lib /usr/lib64 2>&1 >> /dev/null ;; 
esac
mkdir -v /var/{log,mail,spool} 2>&1 >> /dev/null
ln -sv /run /var/run 2>&1 >> /dev/null
ln -sv /run/lock /var/lock 2>&1 >> /dev/null
mkdir -pv /var/{opt,cache,lib/{misc,locate},local} 2>&1 >> /dev/null

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin 2>&1 >> /dev/null
ln -sv /tools/bin/perl /usr/bin 2>&1 >> /dev/null
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib 2>&1 >> /dev/null
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib 2>&1 >> /dev/null
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh 2>&1 >> /dev/null
touch /etc/mtab 2>&1 >> /dev/null
touch /var/log/{btmp,lastlog,wtmp} 2>&1 >> /dev/null
chgrp -v utmp /var/log/lastlog 2>&1 >> /dev/null
chmod -v 664  /var/log/lastlog 2>&1 >> /dev/null
chmod -v 600  /var/log/btmp 2>&1 >> /dev/null
exit 0
EOF
chmod +x $LFS/prelfs.sh

mkdir -pv  $LFS/etc 2>&1 >> /dev/null
cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > $LFS/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
mail:x:34:
nogroup:x:99:
EOF

chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash /prelfs.sh

echo 1 > lfsdone
fi
#echo "LFS=$LFS"
if [ $? -eq 0 ]; then
	echo -e "\033[32m\t\t\t\tOK\033[0m"
else
	echo -e "\033[31m\t\t\t\tFAIL\033[0m"
fi
