#!/bin/sh
IMG=$1
op=$2
if [ $# -ne 2 ]; then
	echo -e "Usage:-\n\t$0 <image> <operation>\n\tAvailable Operations:- attach, detach"
fi

# Initial Setups
mkdir -p /mnt/part1
mkdir -p /mnt/part2
mkdir -p /mnt/part3

detach_parts ()
{
	#Cleanups
	umount /mnt/part3 2>/dev/null
	umount /mnt/part2 2>/dev/null
	umount /mnt/part1 2>/dev/null

	losetup -d /dev/loop2 2>/dev/null
	losetup -d /dev/loop1 2>/dev/null
	losetup -d /dev/loop0 2>/dev/null
}
attach_parts ()
{
	#Do the cleanup
	detach_parts
	#Get the Partitions
	fdisk_result=$( fdisk -l $IMG | grep ".img[1-9]" )
	echo "Current Patitions....."
	echo -e "$fdisk_result"	
	total_parts=$( echo -e "$fdisk_result" | wc -l)
	echo -e "\n\nTotal Number of partitions: $total_parts"
	partno=1;
	while [ $partno -le $total_parts ]; do
		echo "Mounting Partition: $partno"
		part_line=$( echo -e "$fdisk_result" | head -${partno} | tail -1 )
		#echo "part_line=${part_line}"
		case $partno in

			1)
			part_start=$( echo "$part_line" | awk '{print $3}')
			;;

			*)
			part_start=$( echo "$part_line" | awk '{print $2}')
			;;
		esac
		#echo "part_start=${part_start}"
		part_offset=$(expr $part_start \* 512 )
		#echo "part_offset=${part_offset}"

		#get a free loopdev
		loop_dev=$(losetup -f)
		#echo "loop_dev=${loop_dev}"
		losetup ${loop_dev} ${IMG} -o${part_offset}
		mount ${loop_dev} /mnt/part${partno}
		echo -e "Partition (/mnt/part${partno}) contaions:-"	
		ls /mnt/part${partno}
		sleep 1
		echo -e "\n\n"	

		#Update to next partition Number .......>
		partno=$( expr $partno + 1)
	done 
}

case $op in

	attach)
	attach_parts
	;;

	detach)
	detach_parts
	echo "Done!!"
	;;
esac


