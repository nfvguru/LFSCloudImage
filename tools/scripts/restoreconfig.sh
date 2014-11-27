#!/bin/sh
SERVER=$1
FILE=$2

if [ "$SERVER" == "" ]; then
	SERVER="10.1.4.71"
fi

if [ "$FILE" == "" ]; then
	ETHIP=$( ifconfig eth0 | grep inet| cut -d':' -f2 | awk '{print $1}' )
	FILE=$( hostname )"_$ETHIP.cfg"
fi


DESTURL="tftp://${SERVER}/${FILE}"
echo -e "ena\n\nconfigure load ${DESTURL}\n" | su - admin
echo "done"

