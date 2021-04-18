#!/bin/bash

function getUtils {
    export MYUID=$(id -u)
    export MYGID=$(id -g)
    export APACHEGID=$(id -g www-data)
    # Gestion de password
    for line in $(cat ${PASSWD_FILE})
    do
    user=$(echo ${line} | awk -F':' '{print $1}')
    pass=$(echo ${line} | awk -F':' '{print $2}')
    export passwd_${user}=${pass}
    done
}