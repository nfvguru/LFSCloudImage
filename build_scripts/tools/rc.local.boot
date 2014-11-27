#!/bin/sh
########################################################################
# Begin rc.local
#
# Description : execute rc.local
#
# Author      : Lavaraj
#
# Version     : LFS 7.0
#
########################################################################

### BEGIN INIT INFO
# Provides:            rc.local
# Required-Start:
# Should-Start:
# Required-Stop:
# Should-Stop:
# Default-Start:       3 4 5
# Default-Stop:        0 1 2 6
# Short-Description:   executes /etc/rc.local
# Description:         execute  /etc/rc.local
# X-LFS-Provided-By:   LFS
### END INIT INFO

. /lib/lsb/init-functions


do_start() {
        if [ -x /etc/rc.local ]; then
                /etc/rc.local
                ES=$?
                return $ES
        fi
}

case "$1" in
    start)
        do_start
        ;;
    restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
        ;;
    stop)
        ;;
    *)
        echo "Usage: $0 start|stop" >&2
        exit 3
        ;;
esac
# End of bootscript
