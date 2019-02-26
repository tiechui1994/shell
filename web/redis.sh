#!/bin/bash

#----------------------------------------------------
# File: redis.sh
# Contents: 安装redis服务
# Date: 18-12-10
#----------------------------------------------------

version="4.0.0"
workdir=$(pwd)/redis-${version}
installdir="/opt/local/redis"

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_source_code() {
    if ! command_exists curl; then
        apt-get update && \
        apt-get install curl
    fi

    url="https://codeload.github.com/antirez/redis/tar.gz"
    curl -o redis-${version}.tar.gz ${url}/${version} && \
    tar -zvxf redis-${version}.tar.gz && \
    cd ${workdir}
}

build_sorce_code() {
    # 目录检测
    if [[ -e ${installdir} ]];then
        rm -rf ${installdir}
    else
        mkdir -p ${installdir} && rm -rf ${installdir}
    fi

    make && make PREFIX=${installdir} install
}

add_config_file() {
    # 修正配置文件
    mkdir -p ${installdir}/conf && \
    cp redis.conf ${installdir}/conf && \
    cp sentinel.conf ${installdir}/conf

    # 删除可能存在的配置文件
    if [[ -e /etc/init.d/redis ]];then
       rm -rf /etc/init.d/redis
    fi

    # 创建配置文件目录
    mkdir ${installdir}/data && \
    mkdir ${installdir}/logs

    # 修改配置文件
    sed -i \
    -e 's|^daemonize.*|daemonize yes|g' \
    -e 's|^supervised.*|supervised auto|g' \
    -e 's|^pidfile.*|pidfile /opt/local/redis/data/redis_6379.pid|g' \
    -e 's|^logfile.*|logfile /opt/local/redis/logs/redis.log|g' \
    -e 's|^dir.*|dir /opt/local/redis/data/|g' \
    ${installdir}/conf/redis.conf

    # 添加服务文件
    cat > /etc/init.d/redis <<-'EOF'
#!/bin/bash

### BEGIN INIT INFO
# Provides:          redis
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: redis service
# Description:       redis service daemon
### END INIT INFO

REDISPORT=6379
EXEC=/usr/local/bin/redis-server
CLIEXEC=/usr/local/bin/redis-cli

PIDFILE=/opt/local/redis/data/redis_${REDISPORT}.pid
CONF=/opt/local/redis/conf/redis.conf

case "$1" in
    start)
        if [[ -f ${PIDFILE} ]]
        then
                echo "${PIDFILE} exists, process is already running or crashed"
        else
                echo "Starting Redis server..."
                $EXEC ${CONF}
        fi
        ;;
    stop)
        if [[ ! -f ${PIDFILE} ]]
        then
                echo "${PIDFILE} does not exist, process is not running"
        else
                PID=$(cat ${PIDFILE})
                echo "Stopping ..."

                ${CLIEXEC} -p ${REDISPORT} shutdown
                if [[ -e ${PIDFILE} ]];then
                    rm -rf ${PIDFILE}
                fi

                while [[ -x /proc/${PID} ]]
                do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
EOF

    # 权限
    chmod a+x /etc/init.d/redis && \
    update-rc.d redis defaults && \
    update-rc.d redis disable $(runlevel | cut -d ' ' -f2)

     # 链接
    ln -sf ${installdir}/bin/redis-cli /usr/local/bin/redis-cli && \
    ln -sf ${installdir}/bin/redis-server /usr/local/bin/redis-server
}

start_redis_service() {
    systemctl daemon-reload && \
    service redis start
    if [[ -n $(netstat -an|grep '127.0.0.1:6379') ]];then
        echo
        echo "INFO: Redis Installed Successful"
        echo
    fi
}

clear_file() {
    cd ../ &&
    rm -rf redis-${version}*
}

do_install() {
    check_user
    download_source_code
    build_sorce_code
    add_config_file
    start_redis_service
    clear_file
}

do_install