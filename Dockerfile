###### grafana images
FROM qnib/alpn-jre8

VOLUME ["/data/zookeeper"]
ARG ZK_VER=3.4.8
ARG ZK_URL=http://apache.claz.org/zookeeper
ENV PATH=/opt/zookeeper/bin:${PATH}

RUN apk add --update curl \
 && curl -fsL ${ZK_URL}/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz | tar xzf - -C /opt \
 && mv /opt/zookeeper-${ZK_VER} /opt/zookeeper \
 && rm -rf /tmp/* /var/cache/apk/*
ADD etc/supervisord.d/zookeeper.ini \
    etc/supervisord.d/zookeeper_update.ini \
    /etc/supervisord.d/
ADD opt/qnib/zookeeper/bin/*.sh /opt/qnib/zookeeper/bin/
ADD etc/consul.d/zookeeper.json /etc/consul.d/
ADD etc/consul-templates/zoo.cfg.ctmpl \
    etc/consul-templates/zoo.myid.ctmpl \
    /etc/consul-templates/
ENV PATH=/opt/zookeeper/bin:${PATH}
RUN echo "tail -f /var/log/supervisor/zookeeper.log" >> /root/.bash_history && \
    echo "cat /opt/zookeeper/conf/zoo.cfg" >> /root/.bash_history
ADD opt/zookeeper/conf/zoo.cfg /opt/zookeeper/conf/
## move to consul-content
ADD opt/qnib/consul/bin/get-uniq-id.sh /opt/qnib/consul/bin/
