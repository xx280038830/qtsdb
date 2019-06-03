#!/usr/bin/env bash

if [ ! "$(whoami)"x == "root"x ]; then
    echo "Please use root user"
    exit -1
fi

if [[ "" = "$1" || "" = "$2" || "" = "$3" || "" = "$4" ]]; then
  echo './install-data.sh [bind-address(8085)] [http-bind-address(8084)] [cluster-list] [data-dir]'
        echo "[cluster-list] format: '[ \"1.1.1.1:1\", \"2.2.2.2:2\" ]'"
        exit -1
fi


function initConfigFile(){
cat > data.conf << EOF
 reporting-disabled = true
 bind-address = {bindIp_port}
[cluster]
  enable-proxy = false
  meta-servers = {metaCluser_add} # meta地址
  meta-auth-enabled=true # 开启meta认证
  meta-user-name = "admin"
  meta-password = "admin"
[data]
  enabled = true
  dir = "{data_dir}/data"
  wal-dir = "{data_dir}/wal"
  index-version = "tsi1"
  query-log-enabled = false
[http]
  enabled = true
  bind-address = {httpIp_port}
[logging]
  filename = "{data_dir}/log/influx-data.log"
  maxsize = 500
  maxage = 7
  maxbackups = 5
EOF
}


function installData(){

WGET_URL='http://download.infrasre.qihoo.net'
INSTALL_DIR='/data1/qtsdb/bin'
rm ${INSTALL_DIR}/influx-data.tar.gz -f
rm ${INSTALL_DIR}/influx-data -rf
wget "${WGET_URL}/influxdb/influx-data.tar.gz" -q -O ${INSTALL_DIR}/influx-data.tar.gz
tar zxf ${INSTALL_DIR}/influx-data.tar.gz -C ${INSTALL_DIR}
rm ${INSTALL_DIR}/influx-data.tar.gz -f

}


bindIp_port=$1
httpIp_port=$2
metaCluser_add=$3
sys_dir=$4


http_port=`echo ${httpIp_port}|awk -F ':' '{print $2}'`
data_dir=${sys_dir}/qdata${http_port}

#check data dir
if [ ! -d "${data_dir}" ];then
    mkdir  -p ${data_dir}
fi

if [ ! -d "/data1/qtsdb/bin" ];then
    mkdir  -p /data1/qtsdb/bin
fi


installData
initConfigFile

DATA_DIR_NEW=$(echo ${data_dir} |sed -e 's/\//\\\//g')
sed -i "s/{data_dir}/${DATA_DIR_NEW}/g" data.conf >> /dev/null 2>&1
sed -i "s/{bindIp_port}/\"${bindIp_port}\"/g" data.conf >> /dev/null 2>&1
sed -i "s/{httpIp_port}/\"${httpIp_port}\"/g" data.conf >> /dev/null 2>&1
sed -i "s/{metaCluser_add}/${metaCluser_add}/g" data.conf >> /dev/null 2>&1
mv data.conf ${data_dir}/qdata${http_port}.cnf
data_bin='/data1/qtsdb/bin/influx-data/influxd-data'
${data_bin} run -daemon=true -config ${data_dir}/qdata${http_port}.cnf
