#!/bin/sh

######################################################################################################
#												     #
#	controlservice command service 							             #		
#                                                                                                    #
######################################################################################################
cmd=$1
service=$2
if [ "$service" == "" ]; then
	service=all

fi 
all="httpd wcpd radiusd dhcpd"

#####################################################################################################
#    PRINT STATUS
#
######################################################################################################
do_status_print () 
{
	srv=$1
	if [ "$srv" == "all" ] ; then
		echo "{" 
		#service --status-all 2>/dev/null | grep is 2>/dev/null | awk '{print "\"$1 " : "  $NF}'
		service --status-all 2>/dev/null | grep is 2>/dev/null | cut -d'.' -f1 | grep -v microcode | awk '{ print "\""$1"\": \""$NF"\"," }'
		echo -e  "\"dummy\":\"stopped\" \n }" 
		return
	fi
	case $srv in
		httpd )
		srv="httpd.original"
		;;

		wcpd )
		srv="wcp-rc"
		;;
	esac
	echo "{"
	service $srv status | awk '{ print "\""$1"\": \""$NF"\"" }'
	echo "}"
}


#####################################################################################################
#   START/STOP SERVICE 
#
######################################################################################################
do_action_on_service ()
{
	command=$1
	srv=$2

	case $command in
		stop )
		success="stopped $srv service"
		failure="failed to stop $srv service"
		;;

		start )
		success="started $srv service"
		failure="failed to start $srv service"
		;;
	esac

	case $srv in
		httpd )
		srv="httpd.original"
		;;

		wcpd )
		srv="wcp-rc"
		;;
	esac
	service $srv $command 2>&1 > /dev/null
	retcode=$?
	if [ $retcode -eq 0 ]; then
	 	echo $success
	else
		echo $failure
	fi 
}

do_job ()
{
	command=$1
	srv=$2

	if [ "$srv" == "all" ] ; then
	 	for srvs in $all; do
			do_action_on_service $command $srvs
		done
		return
	fi
	do_action_on_service $command $srv
}

case $cmd in
	start | stop )
	do_job $cmd $service
	;;
	
	status)
	do_status_print $service
	;;

	*)
	;;
esac

