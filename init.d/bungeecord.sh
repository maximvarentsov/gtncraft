#! /bin/bash

### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    BunGeecord
# Description:    Starts the BunGeecord server
### END INIT INFO

SERVER='BungeeCord.jar'
SCREENAME="BungeeCord"
USER='minecraft'
HEAP_MAX=512
HEAP_MIN=512
HISTORY=32
HOME="/home/minecraft/${SCREENAME}"
INVOCATION="java -Xmx${HEAP_MAX}M -Xms${HEAP_MIN}M -jar ${SERVER}"
ME=`whoami`

as_user() {
  if [ ${ME} == ${USER} ] ; then
    bash -c "$1"
  else
    su - ${USER} -c "$1"
  fi
}

cmd() {
  command="$1";
  logfile="${HOME}/proxy.log.0"
  if server_running
  then
    pre_log_len=`wc -l "${HOME}/proxy.log.0" | awk '{print $1}'`
    as_user "screen -p 0 -S ${SCREENAME} -X eval 'stuff \"${command}\"\015'"
    sleep .2
    V=`wc -l ${logfile} | awk '{print $1}'`-${pre_log_len}
    tail -n $[V] ${logfile}
  else
    echo "${SERVER} was not running. Not able to run command."
  fi
}

server_running() {
  if ps ax | grep SCREEN | grep ${SCREENAME} | grep ${SERVER} > /dev/null
  then
    return 0
  else
    return 1
  fi
}

start() {
  if server_running
  then
    echo "${SCREENAME} is already running!"
  else
    as_user "cd ${HOME} && screen -h ${HISTORY} -dmS ${SCREENAME} ${INVOCATION}"
    if server_running
    then
      echo "${SCREENAME} is now running."
    else
      echo "Error! Could not start ${SCREENAME}!"
    fi
  fi
}

stop() {
  if server_running
  then
    echo "Stopping ${SCREENAME}"
    cmd end
  else
    echo "${SCREENAME} was not running."
  fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    sleep 5
    start
    ;;
  status)
    if server_running
    then
      echo "${SCREENAME} is running."
    else
      echo "${SCREENAME} is not running."
    fi
    ;;

  *)
  echo "Usage: $0 {start|stop|status|restart}"
  exit 1
  ;;
esac

exit 0
