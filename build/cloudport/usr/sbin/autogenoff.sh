#!/bin/sh

#lastpid=$(pgrep -x -o  $(list=$(ps -ef| grep openvpn | awk '{ print $2}');))
#pgm="openvpn"
#lastpid=$( pgrep -x -o $pgm )
list=$(ps -ef| grep "openvpn" |grep -v 'grep' | awk '{ print $2}')

#echo lastpid = $lastpid 
#echo list = $list
for i in $list;
 do
#       echo $i ;
        kill $list
 done


