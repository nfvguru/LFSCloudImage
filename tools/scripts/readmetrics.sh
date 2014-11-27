#!/bin/sh

read_aps_discovered ()
{
	mode=$1
	case $mode in
	 discovered)
		pattern="discovered"
		;;
	 activated)
		pattern="AP Name:"
	esac
	#WCPD status
        wcpd_running=$(/opt/nfvo/controlservice.sh status wcpd | grep -c stopped)
	if [ $wcpd_running -eq 1 ] ; then
		no_aps=0
	else

	 	no_aps=$( echo -e "show ap info ${mode}\n" | unscli | grep -c "${pattern}" )
		if [ "$no_aps" == "" ]; then
			no_aps=0
		fi
	fi
	echo $no_aps
}

#read_aps_discovered
ap_d=$( read_aps_discovered discovered)
ap_a=$( read_aps_discovered activated)
echo -e  "{ \n \"ap_new\": $ap_d,\n \"ap_activated\": $ap_a \n }"
