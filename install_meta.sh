#!/usr/bin/env bash

if [ ! "$(whoami)"x == "root"x ]; then
    echo "Please use root user"
    exit -1
fi

if [[ "" = "$1" || "" = "$2" || "" = "$3" || "" = "$4" ]]; then
  echo './install-meta.sh [bind-address(8085)] [http-bind-address(8084)] [data-dir] [master/slave]'
        exit -1
fi


function initConfigFile(){
cat > meta.conf << EOF
 reporting-disabled = true
[meta]
  enabled = true
  dir = "{data_dir}/meta"
  bind-address = {bindIp_port}
  http-bind-address = {httpIp_port}
  auth-enabled = true # 开启meta验证
  user-name = "admin"
  password = "admin"
 [data]
  enabled = false
[monitor]
  store-enabled = false
[logging]
  format = "auto"
  filename = "{data_dir}/log/influx-meta.log"
  maxsize = 500
  maxage = 7
  maxbackups = 5
EOF
}


function installMeta(){

WGET_URL='http://download.infrasre.qihoo.net'
INSTALL_DIR='/data1/qtsdb/bin'
rm ${INSTALL_DIR}/influx-meta.tar.gz -f
rm ${INSTALL_DIR}/influx-meta -rf
wget "${WGET_URL}/influxdb/influx-meta.tar.gz" -q -O ${INSTALL_DIR}/influx-meta.tar.gz
tar zxf ${INSTALL_DIR}/influx-meta.tar.gz -C ${INSTALL_DIR}
rm ${INSTALL_DIR}/influx-meta.tar.gz -f

}


bindIp_port=$1
httpIp_port=$2
sys_dir=$3
role=$4



http_port=`echo ${httpIp_port}|awk -F ':' '{print $2}'`
data_dir=${sys_dir}/qmeta${http_port}

#check data dir
if [ ! -d "${data_dir}" ];then
    mkdir  -p ${data_dir}
fi

if [ ! -d "/data1/qtsdb/bin" ];then
    mkdir  -p /data1/qtsdb/bin
fi


installMeta
initConfigFile

DATA_DIR_NEW=$(echo ${data_dir} |sed -e 's/\//\\\//g')
sed -i "s/{data_dir}/${DATA_DIR_NEW}/g" meta.conf >> /dev/null 2>&1
sed -i "s/{bindIp_port}/\"${bindIp_port}\"/g" meta.conf >> /dev/null 2>&1
sed -i "s/{httpIp_port}/\"${httpIp_port}\"/g" meta.conf >> /dev/null 2>&1
mv meta.conf ${data_dir}/qmeta${http_port}.cnf
meta_bin='/data1/qtsdb/bin/influx-meta/influxd-meta'

if [ ${role} == "master" ]
then
    ${meta_bin} run -daemon=true -config ${data_dir}/qmeta${http_port}.cnf -bootstrap -join  ${httpIp_port}
else
    ${meta_bin} run -daemon=true -config ${data_dir}/qmeta${http_port}.cnf
fi
