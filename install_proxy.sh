#!/usr/bin/env bash

if [ ! "$(whoami)"x == "root"x ]; then
    echo "Please use root user"
    exit -1
fi

if [[ "" = "$1" || "" = "$2" || "" = "$3" || "" = "$4" ]]; then
  echo './install-proxy.sh [bind-address(8085)] [http-bind-address(8084)] [cluster-list] [data-dir]'
        echo "[cluster-list] format: '[ \"1.1.1.1:1\", \"2.2.2.2:2\" ]'"
        exit -1
fi


function initConfigFile(){
cat > proxy.conf << EOF
 reporting-disabled = true
 bind-address = {bindIp_port}
[cluster]
  enable-proxy = true
  meta-servers = {metaCluser_add} #meta地址
  shard-writer-timeout = "5s"
  read-timeout = "1000s"
  write-timeout = "10s"
  max-remote-write-connections = 30000
  slowlog-log-slower-than =0 #慢查询触发
  log-slow = true  #是否开启慢查询
  meta-auth-enabled=true  # meta验证
  meta-user-name = "admin"
  meta-password = "admin"
[hinted-handoff]
  enabled = true
  dir = "{data_dir}/hh"
  max-size = 1073741824
  max-age = "168h"
  retry-rate-limit = 0
  retry-interval = "1s"
  retry-max-interval = "1m"
  purge-interval = "1h"
[http]
   bind-address = {httpIp_port}
   auth-enabled = true
   max-connection-limit = 10000
   backup-dir = "{data_dir}/backup" # 通过proxy备份集群存储位置
[logging]
  filename = "{data_dir}/log/influx-proxy.log"
  maxsize = 500
  maxage = 7
  maxbackups = 5
  query_filename = "{data_dir}/log/slow.log"
EOF
}


function installProxy(){

WGET_URL='http://download.infrasre.qihoo.net'
INSTALL_DIR='/data1/qtsdb/bin'
rm ${INSTALL_DIR}/influx-proxy.tar.gz -f
rm ${INSTALL_DIR}/influx-proxy -rf
wget "${WGET_URL}/influxdb/influx-proxy.tar.gz" -q -O ${INSTALL_DIR}/influx-proxy.tar.gz
tar zxf ${INSTALL_DIR}/influx-proxy.tar.gz -C ${INSTALL_DIR}
rm ${INSTALL_DIR}/influx-proxy.tar.gz -f

}


bindIp_port=$1
httpIp_port=$2
metaCluser_add=$3
sys_dir=$4
log_dir=$5®®


installProxy
initConfigFile

http_port=`echo ${httpIp_port}|awk -F ':' '{print $2}'`
data_dir=${sys_dir}/qproxy${http_port}


#check data dir
if [ ! -d "${data_dir}" ];then
    mkdir  -p ${data_dir}
fi

if [ ! -d "/data1/qtsdb/bin" ];then
    mkdir  -p /data1/qtsdb/bin
fi
DATA_DIR_NEW=$(echo ${data_dir} |sed -e 's/\//\\\//g')
sed -i "s/{data_dir}/${DATA_DIR_NEW}/g" proxy.conf >> /dev/null 2>&1
sed -i "s/{bindIp_port}/\"${bindIp_port}\"/g" proxy.conf >> /dev/null 2>&1
sed -i "s/{httpIp_port}/\"${httpIp_port}\"/g" proxy.conf >> /dev/null 2>&1
sed -i "s/{metaCluser_add}/${metaCluser_add}/g" proxy.conf >> /dev/null 2>&1
mv proxy.conf ${data_dir}/qproxy${http_port}.cnf
proxy_bin='/data1/qtsdb/bin/influx-proxy/influxd-proxy'
${proxy_bin} run -daemon=true -config ${data_dir}/qproxy${http_port}.cnf
