#!/usr/local/bin/dumb-init /bin/bash

source /opt/qnib/consul/etc/bash_functions.sh
wait_for_srv consul-http

if [ -f /etc/docker-hostname ];then
  if [ $(cat /etc/conf.d/hostname |grep -c =) -eq 1 ];then
    export CONSUL_ID_KEY=$(egrep -o "^\w+.*" /etc/conf.d/hostname |awk -F\= '{print $2}' |tr -d '"')
  else
    export CONSUL_ID_KEY=$(tail -n1 /etc/docker-hostname)
  fi
else
  export CONSUL_ID_KEY=$(cat /etc/hostname)
fi

if [ "X${ZK_USE_CONTAINER_NAME}" = "Xtrue" ];then
  DOCKER_NET=$(ip -o -4 ad |egrep -o "172[0-9\.]+\.0")
  export DOCKER_HOST=${DOCKER_NET}.1:2376
  DOCKER_CONTAINER_NAME=$(go-getmyname)
  if [ "X${DOCKER_CONTAINER_NAME}" == "X" ];then
    echo "!! Not able to determine container name with ${DOCKER_HOST}"
    sleep 5
    exit 1
  fi
  CNT_ID=$(echo ${DOCKER_CONTAINER_NAME} |awk -F\. '{print $2}')
  export MYID=$(echo "${CNT_ID}"+1 |bc)
elif [ "X${ZK_USE_CONSUL}" = "Xtrue" ];then
  export MYID=$(/opt/qnib/consul/bin/get-uniq-id.sh zookeeper)
fi

export MYID=${MYID-"-1"}
if [ "${MYID}" == "-1" ];then
    supervisorctl start zookeeper
    exit 0
fi

consul-template -consul localhost:8500 -once -template "/etc/consul-templates/zoo.myid.ctmpl:/tmp/zookeeper/myid"

if [ "X${ZK_DC}" != "X" ];then
    sed -i'' -E "s#service \"zookeeper(@\w+)?\"#service \"zookeeper@${ZK_DC}\"#" /etc/consul-templates/zoo.cfg.ctmpl
fi

if [ "X${ZK_MIN}" != "X" ];then
    ZK_CNT=0
    while [ ${ZK_CNT} -ne ${ZK_MIN} ];do
        ZK_CNT=$(curl -Ls "localhost:8500/v1/catalog/service/zookeeper?dc=${ZK_DC-dc1}"|python -m json.tool|grep -c Node)
        sleep 5
    done
fi

if [ "${MYID:-0}" -gt 0 ];then
   echo ">> Sleep according to MYID $(echo "${MYID}*2"|bc)"
   sleep $(echo "${MYID}*2"|bc)
fi

consul-template -consul localhost:8500 -wait=15s -template "/etc/consul-templates/zoo.cfg.ctmpl:/opt/zookeeper/conf/zoo.cfg:supervisorctl restart zookeeper"
exit 0
