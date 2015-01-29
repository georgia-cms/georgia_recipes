#!/bin/sh
### BEGIN INIT INFO
# Provides:          sidekiq
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage sidekiq
# Description:       Start, Stop, Restart sidekiq
### END INIT INFO
set -e

NAME=sidekiq
PIDFILE=<%= sidekiq_pid %>
DAEMON="sudo -u <%= user %> /home/deployer/.rbenv/shims/bundle exec sidekiq --index 0 --pidfile <%= sidekiq_pid %> --environment <%= rails_env %> --logfile <%= sidekiq_log %> --daemon"
DIR="<%= current_path %>"

AS_USER=<%= user %>
set -u

case "$1" in
  start)
    echo -n "Starting Sidekiq"
    cd $DIR
    $DAEMON
    echo "."
  ;;
  stop)
    echo -n "Stopping Sidekiq"
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
    echo -n "Restarting Sidekiq"
    pid=`cat "$PIDFILE"` 2> /dev/null
    if [ "$pid" != "" ]; then
      if ! kill $pid > /dev/null 2>&1; then
        echo "Could not send SIGTERM to process $pid" >&2
      fi
      rm $PIDFILE
    fi
    cd $DIR
    $DAEMON
    echo "."
  ;;

  *)
  echo "Usage: "$1" {start|stop|restart}"
  exit 1
esac

exit 0