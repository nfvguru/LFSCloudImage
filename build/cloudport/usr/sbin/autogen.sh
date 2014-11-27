#!/bin/bash

#echo "Reached ..."
 TimesVal=$2;
 Interval=$1;

 usage() {
    T="$(date +%s)"
    sleep $Interval
 }

 for (( i=0; i<$TimesVal; i++ ))
   do
#	 echo "Trying to execute"
         sudo /opt/openvpn2.3.4/openvpn /opt/openvpn2.3.4/client.conf &
	 usage
   done
