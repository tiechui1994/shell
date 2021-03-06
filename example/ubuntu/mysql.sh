#!/bin/bash

#----------------------------------------------------
# File: install.sh
# Contents: install mysql-5.7 on ubuntu 14.04/16.04
# Date: 8/19/19
#----------------------------------------------------

release=""
version="5.7.26"

loge() {
    echo -e "\e[1;31mERROR|$@\e[0m"
}

logi() {
    echo -e "\e[1;32mINFO|$@\e[0m"
}

logw() {
     echo -e "\e[1;33mWARN|$@\e[0m"
}

check_user() {
    if [[ $(whoami) != "root" ]]; then
        loge "Please use root execute script"
        exit -1
    fi
}

check_os_version() {
    if [[ -e "/etc/lsb-release" ]]; then
        . /etc/lsb-release
        release="${DISTRIB_RELEASE}"
    fi

    if [[ -e "/etc/issue.net" ]];then
        release="$(cat /etc/issue.net|cut -d ' ' -f2|grep -E -o '1[0-9]{1}.[0-9]{2}')"
    fi

    logi "Current Ubuntu Version: $release"
}

check_mysql() {
    cmd="$(command -v 'mysqld')"
    if [[ $? -eq 0 ]]; then
        info=$(${cmd} --verbose --version)
        logw "MySQL server exists. Version is: $info"
        exit -2
    fi
}

download_deb() {
    logi "Start download deb files ..."

    url="https://mirrors.cloud.tencent.com/mysql/apt/ubuntu/pool/mysql-5.7/m/mysql-community"
    files=([0]="mysql-community-server_${version}-1ubuntu${release}_amd64.deb"
           [1]="mysql-community-client_${version}-1ubuntu${release}_amd64.deb"
           [2]="mysql-common_${version}-1ubuntu${release}_amd64.deb"
           [3]="mysql-client_${version}-1ubuntu${release}_amd64.deb")

    for i in ${files[@]}; do
        logi "url: $url/$i"
        if [[ -e "/usr/bin/wget" ]]; then
            wget "$url/$i" > /dev/null 2>&1
            continue
        fi

        if [[ -e "/usr/bin/curl" ]]; then
            curl -o "$i" "$url/$i" > /dev/null 2>&1
            continue
        fi
    done

    logi "End download deb files ..."
}

install_deb() {
    logi "Install deb ..."

    apt-get update && \
    apt-get install -y libaio1 libmecab2

    dpkg -a -i mysql-*.deb
    if [[ $? -eq 0 ]]; then
        count=$(dpkg -l|grep mysql|grep ${version}-1ubuntu${release}|wc -l)
        if [[ ${count} -eq 4 ]]; then
            logi "Install MySQL-$version Success !!!"
            return 0
        fi
    fi

    loge "Install MySQL-$version Failed, Please Check Reason."
    exit -3
}

_input_password() {
     read -p "Input your root password: " new
     len=${#new}
     if [[ ${len} -lt 6 ]]; then
         _input_password
         return
     fi

     echo ${new}
}

init_mysql() {
    if [[ ${release} == "14.04" ]]; then
        service mysql start
    fi

    if [[ ${release} == "16.04" ||  ${release} == "18.04" ]]; then
        systemctl start mysql.service
    fi

    if [[ $? -eq 0 ]]; then
        old_pwd=$(cat /var/log/mysql/error.log | grep 'temporary password' | cut -d ' ' -f11)
        new_pwd=$(_input_password)
        cat > /tmp/update.sql <<- EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY "${new_pwd}";
        COMMIT;
EOF
        if [[ ${old_pwd} ]]; then
            mysql --connect-expired-password -h localhost -u root -p${old_pwd} mysql </tmp/update.sql > /dev/null 2>&1
        else
            mysql -h localhost -u root mysql </tmp/update.sql > /dev/null 2>&1
        fi
        if [[ $? -eq 0 ]]; then
            rm -rf /tmp/update.sql
            logi "Update Password Success"
            return
        else
            rm -rf /tmp/update.sql
            loge "Update Password Failed. Please Check Reason"
            exit -4
        fi
    fi

    loge "Start MySQL Failed, Please Check Reason."
    exit -5
}

install(){
    check_user
    check_os_version
    check_mysql
    download_deb
    install_deb
    init_mysql
}

install
