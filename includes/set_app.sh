#!/bin/bash
function addOrRemoveAppFromDNS {
    cd ansible || exit 1
    ansible-playbook -i hosts site.yml --extra-vars "username=${username} application=${appSearched} state=$1"
    cd ..
}

function setDesiredStatusOfApp {    
    appSearched=$1
    appSearchedOfUser=$1_${username}
    desiredStatus=$2
    appInstalled=`docker ps -a --format "{{.Names}}" --filter "label=app.user=${appSearchedOfUser}"`
    if [ "${appSearchedOfUser}" == "${appInstalled}" ] && [ "${desiredStatus}" == "yes" ]
    then
        echo "[${appSearchedOfUser}] est déja installée..."
    elif [ "${appSearchedOfUser}" == "${appInstalled}" ] && [ "${desiredStatus}" != "yes" ]
    then
        case "${appSearched}" in
        nextcloud )
            docker stop ${appInstalled}
            docker stop nextcloud_db_${username}
            docker rm ${appInstalled}
            docker rm nextcloud_db_${username}
            sed -i "/# start ${appSearched}/,/# end ${appSearched}/d" docker-compose/${username}.yml
            ;;
        filerun )
            docker stop ${appInstalled}
            docker stop ${appInstalled}_db_${username}
            docker rm ${appInstalled}
            docker rm ${appInstalled}_db_${username}
            sed -i "/# start ${appSearched}/,/# end ${appSearched}/d" docker-compose/${username}.yml
            ;;
        * )
            docker stop ${appInstalled}
            docker rm ${appInstalled}
            sed -i "/# start ${appSearched}/,/# end ${appSearched}/d" docker-compose/${username}.yml
            ;;
        esac
        addOrRemoveAppFromDNS absent
    elif [ "${appSearchedOfUser}" != "${appInstalled}" ] && [ "${desiredStatus}" != "yes" ]
    then
        echo "[${appSearchedOfUser}] non modifiée"
    else
        case "${appSearched}" in
        filebrowser )
            modifyTemplateOfUser
            getFilemanagerPassword
            ;;
        rutorrent )
            modifyTemplateOfUser
            searchRtorrentPort
            installCustomPlugins
            ;;
        nextcloud )
            modifyTemplateOfUser
            setDBNextcloudPassword
            ;;
        * ) 
            modifyTemplateOfUser
            ;;
        esac
        addOrRemoveAppFromDNS present
    fi
}

function checkIfRebootNeeded {
    
    nb_lines_compose=`awk 'END{print NR}' docker-compose/${username}.yml`
    if [ "${nb_lines_compose}" -gt 15 ]
    then
        docker-compose $(echo "-f docker-compose/${username}.yml";) down
        docker-compose $(echo "-f docker-compose/${username}.yml";) up -d
        docker stop sftp
        docker-compose up -d sftp
    else
        echo "Aucun redémarrage, il n'y a pas d'application"
        exit 0
    fi
    
}

function installCustomPlugins {
    if [ -z "$(ls -A ${DATA_DIR}/${username}/config/torrent/custom_plugins)" ]
    then
        sudo git clone https://github.com/Gyran/rutorrent-ratiocolor.git  ${DATA_DIR}/${username}/config/torrent/custom_plugins/ratiocolor
        sudo git clone https://github.com/xombiemp/rutorrentMobile.git ${DATA_DIR}/${username}/config/torrent/custom_plugins/mobile
    fi
}