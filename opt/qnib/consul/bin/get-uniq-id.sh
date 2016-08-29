#!/usr/local/bin/dumb-init /bin/bash

SRV_STRING=${1:-generic}
if [ -f /etc/conf.d/docker-hostname ] &&  [ $(egrep -o "^\w+.*" /etc/conf.d/hostname |grep -c =) -eq 1 ];then
    HOSTNAME=$(egrep -o "^\w+.*" /etc/conf.d/hostname |awk -F\= '{print $2}' |tr -d '"')
elif [ -f /etc/docker-hostname ];then
    HOSTNAME=$(tail -n1 /etc/docker-hostname)
else
  HOSTNAME=$(cat /etc/hostname)
fi
FIRST_ID=${2:-1}

function get_free {
    consul-cli kv read ${SRV_STRING}/free-ids
}
function set_free {
    consul-cli kv write ${SRV_STRING}/free-ids $1
}

function get_last {
    consul-cli kv read ${SRV_STRING}/last-id
}

function set_last {
    consul-cli kv write ${SRV_STRING}/last-id $1
}


SESSION_ID=$(consul-cli kv lock ${SRV_STRING}/lock)
if [ $(consul-cli kv keys ${SRV_STRING}/ |grep -c ${HOSTNAME}) -eq 1 ];then
    MY_ID=$(consul-cli kv read ${SRV_STRING}/${HOSTNAME})
else
    FREE_IDS=$(get_free)
    if [ "X${FREE_IDS}" == "X" ];then
        LAST_ID=$(get_last)
        if [ "X${LAST_ID}" == "X" ];then
             MY_ID=${FIRST_ID}
             set_last ${MY_ID}
        else
            MY_ID=$(echo ${LAST_ID}+1 |bc)
            set_last ${MY_ID}
        fi
    else
        MY_ID=$(python -c "import sys ; print sys.argv[1].split(',')[-1]" ${FREE_IDS})
        FREE_IDS=$(python -c "import sys ; print ','.join([x for x in sorted(sys.argv[1].split(',')) if x != sys.argv[2]])" ${FREE_IDS} ${MYID})
        set_free ${FREE_IDS}
    fi
fi
consul-cli kv write ${SRV_STRING}/${HOSTNAME} ${MY_ID}
consul-cli kv write ${SRV_STRING}/$(cat /etc/hostname) ${MY_ID}
if [ "X${USE_GETHOSTNAME}" == "Xtrue" ];then
   consul-cli kv write ${SRV_STRING}/$(go-getmyname) ${MY_ID}
fi
consul-cli kv unlock ${SRV_STRING}/lock --session ${SESSION_ID}
echo ${MY_ID}
