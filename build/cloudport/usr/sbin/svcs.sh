#!/bin/sh

SVC=$1
CMD=$2
openvpn_loc=/opt/openvpn2.3.4/openvpn
work=/opt/openvpn2.3.4
#vmon_loc=/home/lemel-lap/newspawn/spawnvpn-master/src/spawnvpn
vmon_loc=/opt/cloudport5.4/vmon/spawnvpn

lb_loc=/opt/loadbalancer2.0
lbvmon=/opt/cloudport5.4/vmon/spawnlb

ssl_loc=/opt/ssloffloader2.0
sslvmon=/opt/cloudport5.4/vmon/spawnssloff


test -n "$SVC" || SVC='-h'
test -n "$CMD" || CMD=status

case "$SVC" in

################################################################
# CORE SERVICES

	logger|poller|openvpn|snort|ffproxy|uproxy|kaspersky|ipsec|xl2tpd|node|container|loadbalancer|ssloffloader|ovpnclient)
		PROG=$SVC
		PGREP="pgrep -P1"
		case "$SVC" in
			ovpnclient)
#                                x=$(ifconfig ) 
#                                echo $x
                                interf=$(ifconfig| grep tun| awk '{print $1}')
                                for x in $interf
                                do
                                   ip=$(ifconfig $x| grep inet)
                                   rx=$(ifconfig $x| grep bytes)
                                   echo '"'$x : $ip $rx'"'
                                done
                                exit
                                ;;

 			container)
                                case "$CMD" in
                                       memusage)
                                                mem=$(free | grep Mem |awk '{print "Total = " $2 ", Used = " $3}')
                                                echo "memusage : $mem"
                                                ;;
                                        cpuusage)
                                                percent=100
                                                cpu=$(mpstat -u | grep all | awk '{print int($12)}')
                                                bal=$(expr $percent - 	$cpu)
                                                echo "cpuusage : $bal% "
                                                ;;
					 all)
#                                                mem=$(free | grep Mem |awk '{print "Total = " $2 ", Used = " $3}')
                                                mem_max=$(free -m | grep Mem |awk '{print $2}')
                                                mem_used=$(free -m | grep Mem |awk '{print $3}')
                                                percent=100
                                                mem_u=$(expr $mem_used \*  $percent)
                                                mem_util=$(expr $mem_u \/ $mem_max)
                                                cpu=$(mpstat -u | grep all | awk '{print int($12)}')
                                                bal=$(expr $percent - $cpu)
                                                echo '"'"mem_size"'"'" : "'"'$mem_max" MB "'",' 
                                                echo '"'"mem_used"'"'" : "'"'$mem_used" MB"'",'
                                                echo '"'"mem_util"'"'" : "'"'$mem_util" % "'",'
                                                echo '"'"cpuusage"'"'" : "'"'$bal" % "'"'
                                                ;;
                                        info)
                                                echo ContainerIP : $(ifconfig | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's/addr://')

                                                ;;
                                        shutdown)
                                                echo "{\n"'"'"Status"'"'" : "'"'"shutting....."'"'"\n}"    
                                                sudo poweroff
                                                ;;

                                esac
                                exit
                                ;;
			loadbalancer)
                                ppid=$(pgrep -x -o $SVC)
                                case "$CMD" in
                                        start)
                                                        if test -n "$ppid" ; then
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Running"'"'" \n}"
                                                        else
                                                               $lb_loc/loadbalancer -f $lb_loc/loadbalance.cfg -d &
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Enabled"'"'" \n}"
                                                        fi
                                                        ;;

                                        stop)
                                                        if test -n "$ppid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Disabled"'"'" \n}"
                                                        else
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Not Running"'"'" \n}"
                                                        fi
                                                        ;;
                                        vmon-start)
                                                        if test -n "$ppid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                $lbvmon
                                                        #       echo WARNING! $SVC is under RADAR
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation started"'"'" \n}"
                                                        elif test -n "$(pgrep -x -o spawnlb)"; then
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Remediation Running"'"'" \n}"
                                                        else
                                                                $lbvmon
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation started"'"'" \n}"
                                                        fi
                                                        ;;
					 vmon-stop)
                                                        vmonpid=$(pgrep -x -o spawnlb)

                                                        if test -n "$vmonpid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $vmonpid
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation stopped"'"'" \n}"
                                                        else
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation Disabled"'"'" \n}"
                                                        fi
                                                        ;;
                                        status)
								 port=$(grep 'current' $lb_loc/loadbalance.cfg -i | cut -d ' ' -f3)
                                                                timestarted=$(ps -eo cmd,etime | grep $SVC | awk '{print $4}')
                                                                echo "{\n" '"'status'"'":""[\n {"
                                                                echo '"'"CurrentProcessID"'"'" : "'"'"$ppid"'",'
                                                                echo '"'"PreviousProcessID"'"'" : "'"'"$(sed -n '1p' /config/$SVC/currprocessid)"'",'
                                                                echo '"'"ServiceUpTime"'"'" : "'"'"$timestarted"'",'
                                                                echo '"'"Port"'"'" : "'"'"$port"'",'
                                                        if test -n "$ppid" ; then
                                                                echo '"'"$SVC"'"'" : "'"'"Enabled"'"'"\n}\n]\n}" 
                                                        else
                                                                echo '"'"$SVC"'"'" : "'"'"Disabled"'"'"\n}\n]\n}" 
                                                        fi
                                                        ;;
                                        restart)
                                                        if test -n "$ppid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                vmonpid=$(pgrep -x -o spawnlb)
                                                                if test -n "$vmonpid" ; then
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                                else
                                                                    $lb_loc/loadbalancer -f $lb_loc/loadbalance.cfg -d 2> /dev/null &
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                                fi
                                                        else
                                                                $lb_loc/loadbalancer -f $lb_loc/loadbalance.cfg -d 2> /dev/null &
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                        fi
                                                        ;;
                                esac
                                exit
                                ;;
			 ssloffloader)
                                ppid=$(pgrep -x -o $SVC)
                                case "$CMD" in
                                        start)
                                                        if test -n "$ppid" ; then
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Running"'"'" \n}"
                                                        else
                                                                #echo "ssloffloader started"
                                                                $ssl_loc/ssloffloader -f $ssl_loc/ssloffload.cfg
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Enabled"'"'" \n}"
                                                        fi
                                                        ;;

                                        stop)
                                                        if test -n "$ppid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Disabled"'"'" \n}"
                                                        else
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Not Running"'"'" \n}"
                                                        fi
                                                        ;;
                                        vmon-start)
                                                        if test -n "$ppid" ; then
                                                                echo "$pid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                $sslvmon
                                                        #       echo WARNING! $SVC is under RADAR
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation started"'"'" \n}"
                                                        elif test -n "$(pgrep -x -o spawnssloff)"; then
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Remediation Running"'"'" \n}"
                                                        else
                                                                $sslvmon
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation started"'"'" \n}"
                                                        fi
                                                        ;;
 					vmon-stop)
                                                        vmonpid=$(pgrep -x -o spawnssloff)

                                                        if test -n "$vmonpid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $vmonpid
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation stopped"'"'" \n}"
                                                        else
                                                                echo "{ \n"'"'"Status"'"'" : "'"'"$SVC  Remediation Disabled"'"'" \n}"
                                                        fi
                                                        ;;
                                        status)
                                                                #port=$(grep 'current' $ssl_loc/ssloffload.cfg | cut -d ' ' -f3)
                                                                port=$(grep 'bind' $ssl_loc/ssloffload.cfg | cut -d ' ' -f2 | cut -d ":" -f2)
                                                                timestarted=$(ps -eo cmd,etime | grep $SVC | awk '{print $4}')
                                                                echo "{\n" '"'status'"'":""[\n {"
                                                                echo '"'"CurrentProcessID"'"'" : "'"'"$ppid"'",'
                                                                echo '"'"PreviousProcessID"'"'" : "'"'"$(sed -n '1p' /config/$SVC/currprocessid)"'",'
                                                                echo '"'"ServiceUpTime"'"'" : "'"'"$timestarted"'",'
                                                                echo '"'"Port"'"'" : "'"'"$port"'",'
                                                        if test -n "$ppid" ; then
                                                                echo '"'"$SVC"'"'" : "'"'"Enabled"'"'"\n}\n]\n}" 
                                                        else
                                                                echo '"'"$SVC"'"'" : "'"'"Disabled"'"'"\n}\n]\n}" 
                                                         #       echo "{ \n"'"'"Status"'"'" : "'"'"$SVC Disabled"'"'" \n}"
                                                        fi
                                                        ;;
                                      restart)
                                                        if test -n "$ppid" ; then
                                                                echo "$ppid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                                kill $ppid
                                                                vmonpid=$(pgrep -x -o spawnssloff)
                                                                if test -n "$vmonpid" ; then
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                                else
                                                                    $ssl_loc/ssloffloader -f $ssl_loc/ssloffload.cfg -d 2> /dev/null &
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                                fi
                                                        else
                                                                $ssl_loc/ssloffloader -f $ssl_loc/ssloffload.cfg -d 2> /dev/null &
                                                                   echo "{\n"'"'"Status"'"'" : "'"'"Restarted"'"'"\n }"
                                                        fi
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
                                        currentipaddr=$(ifconfig tun0 | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}')
                                          echo "{"
                                          echo '"'status'"'":""["
                                          echo "{"
                                        echo '"'$SVC'"'":"'"'$config'"', 
                                        echo '"CurrentProcessID"'":"'"'$pid'"', 
                                        echo '"PreviousProcessID"'":"'"'$(sed -n '1p' /config/$SVC/currprocessid )'"',
                                        echo '"ServiceUpTime"'":"'"'$timestarted'"',
                                        echo '"TunnelIP"'":"'"'$currentipaddr'"'
                                        echo "}"
                                        echo "]"
                                        echo "}"

                                else
                                        #echo $SVC is $config and not running
                                        echo "{"
                                        echo '"'status'"'":""["
                                        echo "{"
                                        echo '"'$SVC'"'":"'"'$config'"', 
                                        echo '"CurrentProcessID"'":"'"'$pid'"', 
                                        echo '"PreviousProcessID"'":"'"'$(sed -n '1p' /config/$SVC/currprocessid )'"',
                                        echo '"ServiceUpTime"'":"'"'$timestarted'"',
                                        echo '"TunnelIP"'":"'"'$currentipaddr'"'
                                        echo "}"
                                        echo "]"
                                        echo "}"
                                fi
				;;
			on|start)
				case "$config" in
					enabled)
						echo "{\n"'"'"Status"'"'" : "'"'" $SVC is already enabled"'"'"\n}"
						;;
					disabled)
						touch /config/$SVC/on && rm -f /config/$SVC/off 2>/dev/null
						echo "{\n"'"'"Status"'"'" : "'"'" $SVC has been enabled"'"'"\n}"
                                                $openvpn_loc $work/server.conf
					        ;;
					uninitialized)
						echo "{\n"'"'"Status"'"'" : "'"'"$SVC is uninitialized, cannot control"'"'"\n}"
						;;
				esac
				;;
			off|stop)
				case "$config" in
					disabled)
						echo "{\n"'"'"Status"'"'" : "'"'"$SVC is already disabled"'"'"\n}"
						;;
					enabled)
						touch /config/$SVC/off && rm -f /config/$SVC/on 2>/dev/null
						echo "$pid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
						#echo $pid
						parpid=$(awk '/PPid:/{print $2}' /proc/$pid/status)
						pkill -P $parpid
						echo "{\n"'"'"Status"'"'" : "'"'"$SVC has been disabled"'"'"\n}"
						;;
					uninitialized)
						echo "{\n"'"'"Status"'"'" : "'"'"$SVC is uninitialized, cannot control"'"'"\n}"
						;;
				esac
				;;
                        vmon-start)
                                if test $status = 1 ; then
                                        case "$SVC" in
                                               openvpn)
                                                       touch /config/$SVC/off && rm -f /config/$SVC/on 2>/dev/null
						       echo "$pid \n $(cat /config/$SVC/currprocessid)" > /config/$SVC/currprocessid
                                                       parpid=$(awk '/PPid:/{print $2}' /proc/$pid/status)
                                                       pkill -P $parpid
                                                       echo WARNING! $SVC is in RADAR
                                                       sleep 1
                                                       $vmon_loc
                                                       ;;
                                        esac
                                else 
                                                       echo inside else WARNING! $SVC is in RADAR
                                                       sleep 1
                                                       $vmon_loc
                                fi
                               ;;
                        vmon-stop)
                                pid2=$(pgrep -x -o spawnvpn)
                                kill -HUP $pid2
				echo "{\n"'"'"Status"'"'" : "'"'"Disabling $SVC Remediation"'"'"\n}"
                               ;;
			restart)
				if test $status = 1 ; then
					case "$SVC" in
						ipsec|xl2tpd)
							/etc/init.d/$SVC restart
							;;
						openvpn)
							#echo "inside restart PROG"
							#pkill $PROG
                                                        parpid=$(awk '/PPid:/{print $2}' /proc/$pid/status)
							echo "{\n"'"'"Status"'"'" : "'"'"$SVC has been restarted"'"'"\n}"
                                                        pkill -P $parpid
                                                        sleep 2
                                                        $openvpn_loc $work/server.conf
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
                                                echo "{\n"'"'"Status"'"'" : "'"'"restarting the service $SVC"'"'"\n}"
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
