#!/bin/bash

function deleteRecordInDomain {
    appInstalled=`docker ps -a --format "{{.Names}}" --filter "label=user=${username}"`
    for app in $appInstalled
    do
        app_name=$(echo $app | cut -d '_' -f1)
        cd ansible || exit 1
        ansible-playbook -i hosts site.yml --extra-vars "username=${username} application=${app_name} state=absent"
        cd ..
    done
}

function actionSeedbox {
    appInstalled=`docker ps -a --format "{{.Names}}" --filter "label=user=${username}"`
    for app in $appInstalled
    do
        docker $1 ${app}
    done
}

function actionAllSeedbox {
    # $1 = stop, start, rm
    for user in $(ls -al ${DATA_DIR}/)
    do
        appInstalled=`docker ps -a --format "{{.Names}}" --filter "label=user=${user}"`
        for app in $appInstalled
        do
            docker $1 ${app}
        done        
    done
}

function recreateSeedbox {
    cd docker-compose || error "Cannot go in docker-compose" 1
    docker-compose -f "${username}.yml" stop
    docker-compose -f "${username}.yml" up -d
}

function deleteData {
    sudo rm -rf ${DATA_DIR}/${username}/data
}

function deleteConfig {
    sudo rm -rf ${DATA_DIR}/${username}/config
}

function deleteHomeUser {
    if [ "${LVM_STATUS}" = "yes" ]
    then
        sudo umount "${DATA_DIR}/${username}"
        sudo sed -i "/${username} /d" /etc/fstab
        sudo rm -rf ${DATA_DIR}/${username}
        sleep 2
        sudo lvremove --yes /dev/${LVM_VG_NAME}/${username} 
        checkLVMDiskStatus
    else
        sudo rm -rf ${DATA_DIR}/${username}
    fi
}

function deleteDockerComposeFile {
    rm -f docker-compose/${username}.yml
}

function deleteFromPasswd {
    htpasswd -D ${PASSWD_FILE} ${username}
}

function deleteFromPureFTP {
docker exec -i pure_ftp /bin/bash << EOC
    pure-pw userdel ${username} -f /etc/pure-ftpd/passwd/pureftpd.passwd
EOC
}

function deleteFromSFTP {
    sed -i "/^${username}:/d" ./sftp/users.conf
}

function actionDockerComposeSeedbox {
    cd docker-compose
    if [ "$2" == "up"]; then
        docker-compose -f $1.yml $2 -d 
    else
        docker-compose -f $1.yml $2
    fi
    cd ..
}
