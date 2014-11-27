#!/bin/sh

#vmon_path = /opt/cloudport5.0/vmon
#vmon_path=/home/ubuntux8664/Angel/FromBadri/CloudPortHaproxy/vmon/
vmon_path=/opt/cloudport5.4/vmon/

tt=$(ls $vmon_path/)
max=$(ls $vmon_path | wc -l)
for file in $tt
do
    pid=$(pgrep -x -o $file)
    if test -n "$pid" ; then
       	case "$file" in
		 spawnlb)
			echo loadbalancer : on
			;;
		spawnssloff)
			echo sslacceleration: on
			;;
		spawnvpn)
			echo openvpn : on
	esac

    fi
done
