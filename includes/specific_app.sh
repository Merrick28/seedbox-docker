#!/bin/bash

function searchRtorrentPort {
    declare -i default_port
    default_port=45001
    
    for file in `ls docker-compose/*.yml`
        do
            current_port=$(grep UserPort ${file} | awk -F ':' '{print $1}'| awk -F '"' '{print $2}')
            if [ ! -z "${current_port}" ] && [[ "$current_port" =~ ^[0-9]+$ ]]
            then
                if [[ ${current_port} -ge ${default_port} ]]
                then
                    default_port=$(( current_port + 1 ))
                fi
            fi
        done
    
    sed -i "s/{{ port }}/${default_port}/g" docker-compose/${username}.yml
}

function getFilemanagerPassword {
    filemanager_password=`docker run --rm filebrowser/filebrowser hash ${password}`
    filemanager_password_escaped=$(echo $filemanager_password | sed 's/\$/\$\$/g')
    sed -i "s|{{ filemanager_password }}|$filemanager_password_escaped|g" docker-compose/${username}.yml 
}

function setDBNextcloudPassword {
    sed -i "s|{{ DB_PASSWORD }}|${password}|g" docker-compose/${username}.yml 
}