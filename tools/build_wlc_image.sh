#!/bin/sh

ROOT=$( pwd )
BUILD=${ROOT}/build
RAWIMAGE="${ROOT}/raw/f300-raw.img"
TARGET_IMG="vWLC_f300_$(date +%d_%h).qcow2"

#Mount the partitions
./updateimage.sh $RAWIMAGE attach

#copy the Scripts
mkdir -pv /mnt/part2/opt/nfvops
cp -dpRvf ${ROOT}/scripts/* /mnt/part2/opt/nfvops

#Detach the partitions
./updateimage.sh $RAWIMAGE detach 

echo "Creating QCOW2 Image......"
sleep 3
#Convert to QCOW2
qemu-img convert -f raw -O qcow2 $RAWIMAGE ${BUILD}/${TARGET_IMG}
