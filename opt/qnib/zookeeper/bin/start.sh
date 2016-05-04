#!/usr/local/bin/dumb-init /bin/sh


## inherited from
# https://raw.githubusercontent.com/mesoscloud/zookeeper/master/3.4.6/centos/7/entrypoint.sh

## In case the zookeeper instance should not be started 
# eg. in case kafka inherits from this image, but uses an external zookeeper

if [ "X${START_ZOOKEEPER}" == "Xfalse" ];then
    echo "Skip starting zookeeper since START_ZOOKEEPER==false"
    rm -f /etc/consul.d/zookeeper.json
    consul reload
    sleep 5
    exit 0
fi

echo ${MYID:-1} > /tmp/zookeeper/myid
if [ "${MYID-0}" -gt 0 ];then
   echo "Sleep according to MYID $(echo "${MYID}*2"|bc)"
   sleep $(echo "${MYID}*2"|bc)
fi
sleep 2
consul-template -consul localhost:8500 -once -template "/etc/consul-templates/zoo.cfg.ctmpl:/opt/zookeeper/conf/zoo.cfg"

/opt/zookeeper/bin/zkServer.sh start-foreground
