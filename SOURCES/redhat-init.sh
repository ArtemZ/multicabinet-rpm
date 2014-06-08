#!/bin/bash
#
# multicabinet2      This shell script takes care of starting and stopping Multicabinet 2
#
# chkconfig: - 80 20
#
### BEGIN INIT INFO
# Provides: multicabinet
# Required-Start: $network $syslog
# Required-Stop: $network $syslog
# Default-Start:
# Default-Stop:
# Description: Enterprise grade billing system
# Short-Description: start and stop multicabinet
### END INIT INFO

## Source function library.
#. /etc/rc.d/init.d/functions
# Source LSB function library. Depends on redhat-lsb package
if [ -r /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
else
    exit 1
fi

DISTRIB_ID=`lsb_release -i -s 2>/dev/null`

NAME="$(basename $0)"
unset ISBOOT
if [ "${NAME:0:1}" = "S" -o "${NAME:0:1}" = "K" ]; then
    NAME="${NAME:3}"
    ISBOOT="1"
fi

# For SELinux we need to use 'runuser' not 'su'
if [ -x "/sbin/runuser" ]; then
    SU="/sbin/runuser"
else
    SU="/bin/su"
fi

# Get the tomcat config (use this for environment specific settings)
TOMCAT_CFG="/usr/local/multicabinet2/etc/tomcat.conf"
if [ -r "$TOMCAT_CFG" ]; then
    . $TOMCAT_CFG
fi


# Define which connector port to use
CONNECTOR_PORT="${CONNECTOR_PORT:-8080}"

# Path to the tomcat launch script
#TOMCAT_SCRIPT="/usr/sbin/tomcat6"

JDK_DIRS="/usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-6-sun /usr/lib/jvm/java-1.5.0-sun /usr/lib/j2sdk1.5-sun /usr/lib/j2sdk1.5-ibm /usr /usr/lib/jvm/jre-1.6.0-openjdk"

for jdir in $JDK_DIRS; do
    if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
	JAVA_HOME="$jdir"
    fi
done
export JAVA_HOME


# Tomcat program name
TOMCAT_PROG="${NAME}"
        
# Define the tomcat username
TOMCAT_USER="${TOMCAT_USER:-multicabinet}"

# Define the tomcat log file
TOMCAT_LOG="${TOMCAT_LOG:-/usr/local/multicabinet2/logs/catalina.out}"

RETVAL="0"

# Look for open ports, as the function name might imply
function findFreePorts() {
    local isSet1="false"
    local isSet2="false"
    local isSet3="false"
    local lower="8000"
    randomPort1="0"
    randomPort2="0"
    randomPort3="0"
    local -a listeners="( $(
                        netstat -ntl | \
                        awk '/^tcp/ {gsub("(.)*:", "", $4); print $4}'
                    ) )"
    while [ "$isSet1" = "false" ] || \
          [ "$isSet2" = "false" ] || \
          [ "$isSet3" = "false" ]; do
        let port="${lower}+${RANDOM:0:4}"
        if [ -z `expr " ${listeners[*]} " : ".*\( $port \).*"` ]; then
            if [ "$isSet1" = "false" ]; then
                export randomPort1="$port"
                isSet1="true"
            elif [ "$isSet2" = "false" ]; then
                export randomPort2="$port"
                isSet2="true"
            elif [ "$isSet3" = "false" ]; then
                export randomPort3="$port"
                isSet3="true"
            fi
        fi
    done
}

# function makeHomeDir() {
#     if [ ! -d "$CATALINA_HOME" ]; then
#         echo "$CATALINA_HOME does not exist, creating"
#         if [ ! -d "/usr/share/${NAME}" ]; then
#             mkdir /usr/share/${NAME}
#             cp -pLR /usr/share/tomcat6/* /usr/share/${NAME}
#         fi
#         mkdir -p /var/log/${NAME} \
#                  /var/cache/${NAME} \
#                  /var/tmp/${NAME}
#         ln -fs /var/cache/${NAME} ${CATALINA_HOME}/work
#         ln -fs /var/tmp/${NAME} ${CATALINA_HOME}/temp
#         cp -pLR /usr/share/${NAME}/bin $CATALINA_HOME
#         cp -pLR /usr/share/${NAME}/conf $CATALINA_HOME
#         ln -fs /usr/share/java/tomcat6 ${CATALINA_HOME}/lib
#         ln -fs /usr/share/tomcat6/webapps ${CATALINA_HOME}/webapps
#         chown ${TOMCAT_USER}:${TOMCAT_USER} /var/log/${NAME}
#     fi
# }

# function parseOptions() {
#     options=""
#     options="$options $(
#                  awk '!/^#/ && !/^$/ { ORS=" "; print "export ", $0, ";" }' \
#                  $TOMCAT_CFG
#              )"
#     if [ -r "/etc/sysconfig/${NAME}" ]; then
#         options="$options $(
#                      awk '!/^#/ && !/^$/ { ORS=" "; 
#                                            print "export ", $0, ";" }' \
#                      /etc/sysconfig/${NAME}
#                  )"
#     fi
#     TOMCAT_SCRIPT="$options ${TOMCAT_SCRIPT}"
# }

# See how we were called.
function start() {
    echo -n "Starting ${TOMCAT_PROG}: "
    # fix permissions on the log and pid files
    #export CATALINA_PID="/var/run/${NAME}.pid"
    #touch $CATALINA_PID
    #chown ${TOMCAT_USER}:${TOMCAT_USER} $CATALINA_PID
    #touch $TOMCAT_LOG
    #chown ${TOMCAT_USER}:${TOMCAT_USER} $TOMCAT_LOG
    # if [ "$CATALINA_HOME" != "/usr/local/multicabinet2/tomcat" ]; then
    #     # Create a tomcat directory if it doesn't exist
    #     makeHomeDir
    #     # If CATALINA_HOME doesn't exist modify port number so that
    #     # multiple instances don't interfere with each other
    #     findFreePorts
    #     sed -i -e "s/8005/${randomPort1}/g" -e "s/8080/${CONNECTOR_PORT}/g" \
    #         -e "s/8009/${randomPort2}/g" -e "s/8443/${randomPort3}/g" \
    #         ${CATALINA_HOME}/conf/server.xml
    # fi
    if [ "$SECURITY_MANAGER" = "true" ]; then
        $SU - $TOMCAT_USER -c "${TOMCAT_SCRIPT} start-security" \
            >> $TOMCAT_LOG 2>&1
    else
	start_daemon -u multicabinet CATALINA_OUT=$CATALINA_OUT $CATALINA_HOME/bin/startup.sh 2>&1
    fi
    RETVAL="$?"
    if [ "$RETVAL" -eq 0 ]; then 
        log_success_msg
        touch /var/lock/subsys/${NAME}
    else
        log_failure_msg
    fi
    if [ "$DISTRIB_ID" = "MandrivaLinux" ]; then
        echo
    fi
    return $RETVAL
}

function stop() {
    RETVAL="0"
    echo -n "Stopping ${TOMCAT_PROG}: "
    if [ -f "/var/lock/subsys/${NAME}" ]; then
	start_daemon -u multicabinet CATALINA_OUT=$CATALINA_OUT	$CATALINA_HOME/bin/shutdown.sh 2>&1
        RETVAL="$?"
        if [ "$RETVAL" -eq "0" ]; then
            # count="0"
            # if [ -f "/var/run/${NAME}.pid" ]; then
            #     read kpid < /var/run/${NAME}.pid
            #     until [ "$(ps --pid $kpid | grep -c $kpid)" -eq "0" ] || \
            #           [ "$count" -gt "$SHUTDOWN_WAIT" ]; do
            #         if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
            #             echo "waiting for processes $kpid to exit"
            #         fi
            #         sleep 1
            #         let count="${count}+1"
            #     done
            #     if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
            #         if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
            #             echo "killing processes which didn't stop after $SHUTDOWN_WAIT seconds"
            #         fi
            #         kill -9 $kpid
            #     fi
            #     log_success_msg
            # fi
            rm -f /var/lock/subsys/${NAME} /var/run/${NAME}.pid
        else
            log_failure_msg
        fi
    else
        log_success_msg
    fi
    if [ "$DISTRIB_ID" = "MandrivaLinux" ]; then
        echo
    fi
    return $RETVAL
}

# See how we were called.
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    condrestart|try-restart)
        if [ -f "/var/run/${NAME}.pid" ]; then
            stop
            start
        fi
        ;;
    reload)
        RETVAL="3"
        ;;
    force-reload)
        if [ -f "/var/run/${NAME}.pid" ]; then
            stop
            start
        fi
        ;;
    status)
        if [ -f "/var/run/${NAME}.pid" ]; then
#           status ${NAME}
#           RETVAL="$?"
            read kpid < /var/run/${NAME}.pid
            if [ -d "/proc/${kpid}" ]; then
                echo "${NAME} (pid ${kpid}) is running..."
                RETVAL="0"
            fi
        else
            pid="$(/usr/bin/pgrep -d , -u ${TOMCAT_USER} -G ${TOMCAT_USER} java)"
            if [ -z "$pid" ]; then
#               status ${NAME}
#               RETVAL="$?"
                echo "${NAME} is stopped"
                RETVAL="3"
            else
                echo "${NAME} (pid $pid) is running..."
                RETVAL="0"
            fi
        fi
        ;;
    version)
        ${TOMCAT_SCRIPT} version
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|condrestart|try-restart|reload|force-reload|status|version}"
        RETVAL="2"
esac

exit $RETVAL

