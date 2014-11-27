#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

#install required packages
if [ ! -f first ]; then
echo "Y" | apt-get install make 2>&1 >> /dev/null
echo "Y" | apt-get install bison 2>&1 >> /dev/null
echo "Y" | apt-get install gcc  2>&1 >> /dev/null
echo "Y" | apt-get install g++ 2>&1 >> /dev/null
echo "Y" | apt-get install texinfo 2>&1 >> /dev/null
#Partition the Hard Disk
echo -e "n\np\n\n\n+40G\na\n3\nn\np\n\n\nw\n" | sudo fdisk /dev/sda 2>&1 >> /dev/null
echo "We need to reboot now to partition....."
echo -e "Press Enter to Reboot \c"
read 
echo 1 > first
reboot
sleep 30
fi
#create filesystem
if [ ! -f second ]; then
mke2fs -jv /dev/sda3 2>&1 >> /dev/null
export LFS=/mnt/lfs
echo "export LFS=/mnt/lfs" >> ~/.bashrc
echo "export LFS=/mnt/lfs" >> /home/build/.bashrc
mkdir -pv $LFS 2>&1 >> /dev/null
mount -v -t ext3 /dev/sda3 $LFS 2>&1 >> /dev/null
mkdir -v $LFS/sources 2>&1 >> /dev/null
chmod -v a+wt $LFS/sources 2>&1 >> /dev/null
cp -dpRvf sources $LFS 2>&1 >> /dev/null
mkdir -v $LFS/tools 2>&1 >> /dev/null
ln -sv $LFS/tools / 2>&1 >> /dev/null
#export LFS=/mnt/lfs
groupadd lfs  2>&1 >> /dev/null
useradd -s /bin/bash -g lfs -m -k /dev/null lfs   2>&1 >> /dev/null
echo -e "lfs\nlfs\n" | passwd lfs  2>&1 >> /dev/null
chmod +x build_scripts/*.sh 2>&1 >> /dev/null
cp -dpRvf build_scripts Makefile Logs config /home/lfs/  2>&1 >> /dev/null
chown -vR lfs /home/lfs  2>&1 >> /dev/null
chown -v lfs $LFS/tools  2>&1 >> /dev/null
chown -v lfs $LFS/sources  2>&1 >> /dev/null
su - lfs -c build_scripts/setupenv.sh 2>&1 >> /dev/null
rm /bin/sh 2>&1 >> /dev/null
ln -s /bin/bash /bin/sh 2>&1 >> /dev/null
chown -vR lfs /home/lfs 2>&1 >> /dev/null
echo 1 > second
fi
echo -e "\033[32m\t\t\t\tOK\033[0m"
#su - lfs -c 'make basetoolchain'
