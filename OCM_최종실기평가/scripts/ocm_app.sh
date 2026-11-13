#!/bin/bash
# ocm.app 액션 스크립트
PIDF=/tmp/ocm_app.pid
case "$1" in
  start) nohup sleep 100000 >/dev/null 2>&1 & echo $! > $PIDF; exit 0 ;;
  stop)  [ -f $PIDF ] && kill $(cat $PIDF) 2>/dev/null; rm -f $PIDF; exit 0 ;;
  check) [ -f $PIDF ] && kill -0 $(cat $PIDF) 2>/dev/null && exit 0; exit 1 ;;
  clean) [ -f $PIDF ] && kill -9 $(cat $PIDF) 2>/dev/null; rm -f $PIDF; exit 0 ;;
esac
