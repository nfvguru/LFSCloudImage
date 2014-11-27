#!/bin/sh

SVC=$1
CMD=$2
openvpn_loc=/opt/openvpn2.3.4/openvpn
work=/opt/openvpn2.3.4


test -n "$SVC" || SVC='-h'
test -n "$CMD" || CMD=status

case "$SVC" in

################################################################
# CORE SERVICES

	logger|poller|openvpn|snort|ffproxy|uproxy|kaspersky|ipsec|xl2tpd|node|container)
		PROG=$SVC
		PGREP="pgrep -P1"
		case "$SVC" in
			container)
                                case "$CMD" in
                                       memusage)
                                                mem=$(free | grep Mem |awk '{print "Total = " $2 ", Used = " $3}')
                                                echo memusage : $mem
                                                ;;
                                        cpuusage)
                                                percent=100
                                                cpu=$(mpstat -u | grep all | awk '{print int($12)}')
                                                bal=$(expr $percent - $cpu)
                                                echo cpuusage : $bal% 
                                                ;;
					all) 
					        mem=$(free | grep Mem |awk '{print "Total = " $2 ", Used = " $3}')
					        percent=100
                                                cpu=$(mpstat -u | grep all | awk '{print int($12)}')
                                                bal=$(expr $percent - $cpu)
						echo memusage : $mem - cpuusage : $bal%
					        ;;
                                        shutdown)
                                                echo "shutting....."    
                                                sudo poweroff
                                                ;;

                                esac
                                exit
                                ;;

			openvpn) PROG=openvpn

				;;
			uproxy|ffproxy)  PROG=universal
				;;
			clamav)  PROG=clamd
				;;
			poller|logger) PROG=logger_client
				;;
			kaspersky) PROG=aveserver
				;;
			ipsec) PROG=pluto; PGREP="pgrep"
				;;
		esac

		#pid=$($PGREP $SVC)
		pid=$(pgrep -x -o $SVC)
		#echo $pid
		if test -n "$pid" ; then
			status=1
		else
			status=0
		fi
		
		if test -f /config/$SVC/on ; then
			config="enabled"
		elif test -f /config/$SVC/off ; then
			config="disabled"
		else
			config="uninitialized"
		fi

		case "$CMD" in
			status)
				if test $status = 1 ; then
                                        timestarted=$(ps -eo cmd,etime | grep $SVC | awk '{print $4}');
                                        #echo time started $(ps -eo cmd,etime | grep $SVC | awk '{print $4}');
					echo $SVC is $config and running at process id:$pid
				else
					echo $SVC is $config and not running
				fi
				;;
			on|start)
				case "$config" in
					enabled)
						echo $SVC is already enabled
						;;
					disabled)
						touch /config/$SVC/on && rm -f /config/$SVC/off 2>/dev/null
						echo $SVC has been enabled
                                                $openvpn_loc $work/server.conf
					        ;;
					uninitialized)
						echo $SVC is uninitialized, cannot control
						;;
				esac
				;;
			off|stop)
				case "$config" in
					disabled)
						echo $SVC is already disabled
						;;
					enabled)
						touch /config/$SVC/off && rm -f /config/$SVC/on 2>/dev/null
						#echo $pid
						parpid=$(awk '/PPid:/{print $2}' /proc/$pid/status)
						pkill -P $parpid
						echo $SVC has been disabled
						;;
					uninitialized)
						echo $SVC is uninitialized, cannot control
						;;
				esac
				;;
			sync)
				if test $status = 1 ; then
					case "$SVC" in
						openvpn)
							pkill -USR1 -P 1 $PROG
							;;
						uproxy|logger|ffproxy)
							pkill -P 1 $PROG
							;;
						snort)
							pkill -INT -P 1 $PROG
							;;
						ipsec)
							/etc/init.d/ipsec reload
							;;
						*)
							pkill -HUP -P 1 $PROG
							;;
					esac

					echo $SVC has been sent signal to sync
				else
					echo $SVC is not running, nothing to sync
				fi
				;;
			restart)
				if test $status = 1 ; then
					case "$SVC" in
						ipsec|xl2tpd)
							/etc/init.d/$SVC restart
							;;
						openvpn)
							echo "inside restart PROG"
							pkill $PROG
							;;
						*)
							pkill -9 $PROG
							;;
					esac
				else
						#kills the parent process of running pid
						#echo "killing the process $SVC at pid $(pgrep -f $SVC)"
						pid1=$(pgrep -x -o $SVC) #find the process id with exact name
						#pname= cat /proc/$pid1/status | grep PPid #find its process nam
						#echo $pname
						#echo $pid1
						parpid1=$(awk '/PPid:/{print $2}' /proc/$pid1/status)
						#echo $parpid1
						pkill -P $parpid1
						echo "restarting the service $SVC"
						$openvpn_loc $work/client.conf 
				fi
				;;
			*)
				echo "unsupported command: $CMD (run $0 -h for help)"
				exit 1
				;;
		esac
		;;
esac

exit $?
~       
