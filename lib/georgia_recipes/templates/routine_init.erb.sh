#!/bin/sh
### BEGIN INIT INFO
# Provides:          <%= routine_name %>
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage <%= routine_name %>
# Description:       Start, Stop, Restart #{routine_name}
### END INIT INFO
set -e

NAME=<%= routine_name %>
PIDFILE=<%= routine_pid %>
DAEMON="/home/deployer/.rbenv/shims/bundle exec <%= routine_bin %>"
DIR="<%= current_path %>"
DAEMON_OPTS="RAILS_ENV=production"

AS_USER=<%= routine_user %>
set -u

case "$1" in
  start)
    echo -n "Starting #{routine_name}"
    cd $DIR
    $DAEMON_OPTS $DAEMON
    echo "."
  ;;
  stop)
    echo -n "Stopping #{routine_name}"
    pid=`cat "$PIDFILE"` 2> /dev/null
    if [ "$pid" != "" ]; then
      if ! kill $pid > /dev/null 2>&1; then
          echo "Could not send SIGTERM to process $pid" >&2
      fi
      rm $PIDFILE
    fi
    echo "."
  ;;
  restart)
    echo -n "Restarting #{routine_name}"
    pid=`cat "$PIDFILE"` 2> /dev/null
    if [ "$pid" != "" ]; then
      if ! kill $pid > /dev/null 2>&1; then
          echo "Could not send SIGTERM to process $pid" >&2
      fi
      rm $PIDFILE
    fi
    cd $DIR
    $DAEMON_OPTS $DAEMON
    echo "."
  ;;

  *)
    echo "Usage: "$1" {start|stop|restart}"
    exit 1
esac

exit 0