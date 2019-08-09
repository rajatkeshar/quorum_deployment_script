#!/bin/sh

TESSERA_PORT=#TESSERA_PORT
RAFT_PORT=#RAFT_PORT
echo `ps -eaf | grep "raftport ${RAFT_PORT}" | awk '{print $2}'`
kill -2 `ps -eaf | grep "raftport ${RAFT_PORT}" | awk '{print $2}'` || true
kill -9 `ps -eaf | grep address=${TESSERA_PORT} | awk '{print $2}'` || true
exit 0
