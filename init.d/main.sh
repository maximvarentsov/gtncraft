#! /bin/bash

### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    Minecraft server
# Description:    Starts the minecraft server
### END INIT INFO

SERVER='spigot.jar'
USERNAME='minecraft'
SCREENAME="main"
WORLD='world'
SERVER_DIR="/home/minecraft/${SCREENAME}"
BACKUP_DIR="/home/minecraft/backups/${SCREENAME}"
MAXHEAP=24768
MINHEAP=12500
HISTORY=1024
CPU_COUNT=16
ME=`whoami`
INVOCATION="/opt/jdk1.8.0_05/bin/java \
-Xmx${MAXHEAP}M -Xms${MINHEAP}M \
-XX:+UseConcMarkSweepGC \
-XX:+CMSIncrementalPacing -XX:ParallelGCThreads=${CPU_COUNT} -XX:+AggressiveOpts \
-XX:+DisableExplicitGC \
-XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled \
-Dfile.encoding=UTF-8 \
-jar ${SERVER}"

as_user() {
  if [ ${ME} == ${USERNAME} ] ; then
    bash -c "$1"
  else
    su - ${USERNAME} -c "$1"
  fi
}

server_running() {
  if ps ax | grep SCREEN | grep ${SERVER} | grep ${SCREENAME} > /dev/null
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
    as_user "cd ${SERVER_DIR} && screen -h ${HISTORY} -dmS ${SCREENAME} ${INVOCATION}"
    if server_running
    then
      echo "Server ${SCREENAME} is now running."
    else
      echo "Error! Could not start ${SCREENAME}!"
    fi
  fi
}

saveoff() {
  if server_running
  then
    cmd save-off
    cmd save-all
    sync
    sleep 10
  else
    echo "${SCREENAME} is not running. Not suspending saves."
  fi
}

saveon() {
  if server_running
  then
    cmd save-on
  else
    echo "${SCREENAME} is not running. Not resuming saves."
  fi
}

stop() {
  if server_running
  then
    echo "Stopping ${SCREENAME}"
    cmd "say Сервер будет перезапушен!"
    cmd save-all
    sleep 10
    cmd stop
    sleep 7
  else
    echo "${SCREENAME} was not running."
  fi
}

backup() {
   saveoff
   NOW=`date "+%Y-%m-%d_%Hh%M"`
   BACKUP_FILE="${BACKUP_DIR}/${WORLD}_${NOW}.tar"
   echo "Backing up minecraft world..."
   as_user "tar -C \"${SERVER_DIR}\" -cf \"${BACKUP_FILE}\" ${WORLD}"
   saveon
   echo "Compressing backup..."
   as_user "gzip -f \"${BACKUP_FILE}\""
   echo "Done."
}

cmd() {
  command="$1";
  logfile="${SERVER_DIR}/logs/latest.log"
  if server_running
  then
    pre_log_len=`wc -l "${SERVER_DIR}/logs/latest.log" | awk '{print $1}'`
    as_user "screen -p 0 -S ${SCREENAME} -X eval 'stuff \"${command}\"\015'"
    sleep .1
    X=`wc -l ${logfile} | awk '{print $1}'`-${pre_log_len}
    tail -n $[X] ${logfile}
  else
    echo "${SCREENAME} was not running. Not able to run command."
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
    start
    ;;
  backup)
    backup
    ;;
  status)
    if server_running
    then
      echo "${SCREENAME} is running."
    else
      echo "${SCREENAME} is not running."
    fi
    ;;
  command)
    if [ $# -gt 1 ]; then
      shift
      cmd "$*"
    else
      echo "Must specify server command (try 'help'?)"
    fi
    ;;

  *)
  echo "Usage: $0 {start|stop|backup|status|restart|command \"server command\"}"
  exit 1
  ;;
esac

exit 0
