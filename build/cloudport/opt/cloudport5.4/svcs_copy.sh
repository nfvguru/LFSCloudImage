#!/bin/sh

SVC=$1
CMD=$2

test -n "$SVC" || SVC='-h'
test -n "$CMD" || CMD=status

case "$SVC" in

################################################################
# CORE SERVICES

	logger|poller|openvpn|snort|ffproxy|uproxy|kaspersky|ipsec|xl2tpd|node)
		PROG=$SVC
		PGREP="pgrep -P1"
		case "$SVC" in
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

		pid=$($PGREP $PROG)
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
					echo $SVC is $config and running as $pid
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
							pkill $PROG
							;;
						*)
							pkill -9 $PROG
							;;
					esac
				fi
				;;
			*)
				echo "unsupported command: $CMD (run $0 -h for help)"
				exit 1
				;;
		esac
		;;

################################################################
# CUSTOM SCRIPTED SERVICES

	iptables|firewall)
		if test -f /config/iptables/on ; then
			config="enabled"
		elif test -f /config/iptables/off ; then
			config="disabled"
		else
			config="uninitialized"
		fi
		case "$CMD" in
			status)
				echo $SVC is $config
				;;
			on|start)
				if test "$config" == "enabled"; then
					echo "iptables is already enabled"
				else
					if test -f /config/iptables/firewall.sh ; then
						touch /config/iptables/on && rm -f /config/iptables/off 2>/dev/null
						echo -n "iptables is loading... please wait... "
						# First run the shorewall generated firewall rules.
						sh /config/iptables/firewall.sh
						# If present, run our custom conntrack rules.
						if test -f /usr/sbin/iptables-conntrack.sh ; then
							sh /usr/sbin/iptables-conntrack.sh
						fi
						/usr/sbin/svcs loadbalance sync
						echo "done"
					else
						echo "iptables missing configuration, cannot enable"
						exit 1
					fi
				fi
				;;
			off|stop)
				if test "$config" == "disabled"; then
					echo "iptables is already disabled"
				else
					touch /config/iptables/off && rm -f /config/iptables/on 2>/dev/null
					echo -n "iptables is being reset to default... please wait... "
					iptables-restore < /etc/network/iptables.default
					echo "done"
				fi
				;;
			sync)
				if test -f /config/iptables/on -a -f /config/iptables/firewall.sh ; then
					if test ! -f /var/run/iptables.sync ; then
						echo "triggering sync on the iptables in 5 seconds... "
						touch /var/run/iptables.sync
						sleep 5
						# temporarily disable logger
						/usr/sbin/svcs logger off
						# First run the shorewall generated firewall rules.
						sh /config/iptables/firewall.sh
						# If present, run our custom conntrack rules.
						if test -f /usr/sbin/iptables-conntrack.sh ; then
							sh /usr/sbin/iptables-conntrack.sh
						fi
						/usr/sbin/svcs loadbalance sync
						/etc/init.d/ipsec reload
						# re-enable logger
						/usr/sbin/svcs logger on
						rm -f /var/run/iptables.sync
						echo "done"
					else
						echo "iptables already being synchronized"
						exit 1
					fi
				else
					echo "iptables cannot perform sync without active configuration"
					exit 1
				fi
				;;
			aliases)
				if test $config == "enabled" -a -f /config/iptables/firewall.sh ; then
					test -f /config/iptables/functions && . /config/iptables/functions
					echo "iptables adding interface aliases... "
					while read line ; do
						set -- $line
						shift
						if test -z "$1" -o -z "$2"; then
							continue
						fi
						add_ip_aliases $*
					done <<EOF
$(cat /config/iptables/firewall.sh | grep add_ip_aliases)
EOF
					echo "done"
				fi
				;;
		esac
		;;


	network|dhcp)
		case "$CMD" in
			status)
				case "$SVC" in
					network) SVCPATH=/config/network/if.d
						;;
					dhcp)    SVCPATH=/config/network
						;;
				esac

				if test -f $SVCPATH/on ; then
					echo "$SVC is configured"
				elif test -f $SVCPATH/off ; then
					echo "$SVC is disabled"
				else
					echo "$SVC is uninitialized, running default configs"
				fi
				;;
			on|off)
				echo "you don't want to do this to $SVC..."
				exit 1
				;;
			sync)
				echo "triggering sync on $SVC in 5 seconds... "
				sleep 5
				/etc/init.d/$SVC reload
			:1	echo "done"
				;;
		esac
		;;

	iproute2)
		case "$CMD" in
			status)
				if test -f /config/iproute2/on ; then
					echo "$SVC is configured"
				elif test -f /config/iproute2/off ; then
					echo "$SVC is disabled"
				else
					echo "$SVC is uninitialized, running default configs"
				fi
				;;
			on|off)
				echo "you don't want to do this to $SVC..."
				exit 1
				;;
			sync)
				echo "triggering sync on $SVC... "
				ip route flush cache
				echo "done"
				;;
		esac
		;;

	patch)
		case "$CMD" in
			status)
				patch=$(cat /var/run/patch 2>/dev/null)
				if test -n "$patch" ; then
					echo "patch is active with version ($patch)"
				else
					echo "patch is not active, no patches applied on system"
				fi
				;;
			on|off)
				echo "you don't want to do this to the patch system..."
				exit 1
				;;
			sync)
				echo "triggering sync on the patch in 5 seconds... "
				sleep 5
				/etc/init.d/patch reload
				echo "done"
				;;
		esac
		;;

	loadbalance)
		case "$CMD" in
			status)
				if test -f /config/loadbalance/on ; then
					echo "$SVC is configured"
				elif test -f /config/loadbalance/off ; then
					echo "$SVC is disabled"
				else
					echo "$SVC is uninitialized, running default configs"
				fi
				;;
			on|off)
				echo "you don't want to do this to $SVC..."
				exit 1
				;;
			sync)
				echo "loadbalance sync disabled for now"
				#echo "triggering sync on $SVC... "
				#pkill -HUP -f -P 1 failover
				#echo "done"
				;;
		esac
		;;

################################################################
# SPECIAL COMMANDS

	all)
		for SVC in network dhcp iproute2 loadbalance iptables openvpn snort logger poller ffproxy uproxy kaspersky ipsec xl2tpd node; do
			$0 $SVC status
		done
		;;

	system)
		for PROG in syslogd klogd httpd crond dnrd rsync dropbear node; do
			pid=$(pgrep $PROG)
			if test -n "$pid" ; then
				status="running as $pid"
			else
				status="not running"
			fi
			echo $PROG is $status
		done
		;;

	info)
		version=$(cat /proc/version)
		clock=$(date -u)
		clock="$clock ("$(date +%s)")"
		uptime=$(uptime)
		ramsize=$(grep 'MemTotal:' /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
		ramfree=$(grep 'MemFree:' /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
		ramused=$(expr $ramsize - $ramfree)
		ramratio=$(expr ${ramused}00 / $ramsize)
#		if test -f /rom/company ; then
#			company=$(cat /rom/company)
#		fi
#		else
#			RAWDEV=$(cat /proc/mtd | grep "RedBoot config" | awk {'print $1'} | cut -d":" -f1)
#			company=$(fconfig -l -d /dev/${RAWDEV} | grep -i oem_brand | awk {'print $2'})
#		fi
		macaddr=$(/sbin/ip -o link show lan0 | sed 's/.*link\/ether[[:space:]]\([^[:space:]]*\)[[:space:]].*/\1/g')
		serial=$(/usr/sbin/maclabel $macaddr 2>/dev/null)
		id="unknown"
		idfile=$(ls /etc/identity/id 2>/dev/null)
		test -f "$idfile" && id=$(cat $idfile)
		patch=$(cat /var/run/patch 2>/dev/null)
		test -n "$patch" || patch="none"
		pid=$(pgrep -f openvpn.*management)
		if test -n "$pid" ; then
			mgmt="management vpn tunnel is running as $pid"
		else
			mgmt="management vpn tunnel is NOT running, this is a CRITICAL ERROR!"
		fi

		cat <<EOF
VERSION: $version
  CLOCK: $clock
 UPTIME:$uptime
    RAM: total ${ramsize}KB, free ${ramfree}KB, used ${ramused}KB, ratio ${ramratio}%
 SERIAL: $serial
 SNAPID: $id
  PATCH: $patch
   MGMT: $mgmt

EOF
		echo "System Services:"
		$0 system
		echo
		echo "Core Services:"
		$0 all
		echo
		;;

	html)
		echo '<ul>'
		for SVC in iptables openvpn poller ffproxy uproxy kaspersky snort node; do
			PROG=$SVC
			NAME=$SVC
			case "$SVC" in
				iptables)  NAME="Firewall Protection"; PROG=init
					;;
				openvpn)   NAME="VPN Security"; PROG=spawnvpn
					;;
				poller)    NAME="Device Monitoring"; PROG=logger_client
					;;
				ffproxy)   NAME="Web Content Filtering"; PROG=universal
					;;
				uproxy)    NAME="Universal Proxy"; PROG=universal
					;;
				kaspersky) NAME="AV Protection"; PROG=aveserver
					;;
				snort)     NAME="Intrusion Detection/Prevention"
					;;
				node)      NAME="Node for Orchestration Call"
					;; 
			esac


			status=
			if test -f /config/$SVC/on ; then
				class=""
				status="is enabled"

				pid=$(pgrep $PROG)
				if test -n "$pid" ; then
					icon="ui-icon-play"
					status="$status and active"
				else
					icon="ui-icon-pause"
					status="$status and inactive"
				fi

			elif test -f /config/$SVC/off ; then
				class="ui-state-disabled"
				icon="ui-icon-alert"
				status="is disabled"
			else
				class="ui-state-disabled"
				icon="ui-icon-info"
				status="is unavailable"
			fi

			echo "<li class=\"$class\"><span class=\"ui-icon $icon\" style=\"float:left; margin-right:0.3em\"></span>$NAME $status</li>"
		done
		echo '</ul>'
		;;

	'-h'|'help'|*)
		echo "usage: $0 (service) (command) [or -h for help]"
		echo "usage: $0 (special command)"
		echo
		echo "valid (services) are: "
		echo " core   - network, dhcp, iproute2, iptables, openvpn, snort, logger, poller, ffproxy, uproxy, kaspersky, ipsec, xl2tpd, node"
		echo
		echo "valid (commands) are: "
		echo " status   - checks the status of configuration and running check"
		echo " on|start - turns the service on (may fail if not configured properly)"
		echo " off|stop - turns the service off (always succeed)"
		echo " restart  - trigger a restart of the service if running"
		echo " sync     - sends a signal to the service to sync configs"
		echo
		echo "valid (special commands) are: "
		echo " all     - shows all core service status"
		echo " system  - shows all system process status"
		echo " info    - shows the current device info along with health info"
		echo " -h|help - displays this message"
		echo
		exit 1
		;;
esac

exit $?
