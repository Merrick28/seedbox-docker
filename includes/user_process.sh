#!/bin/bash

function createDefaultDirectory {
    if [ ! -d "${DATA_DIR}/${username}/data" ]
    then    
        sudo mkdir -p ${DATA_DIR}/${username}/config
       
        sudo mkdir -p ${DATA_DIR}/${username}/data
        sudo mkdir -p ${DATA_DIR}/${username}/nextcloud
        sudo touch ${DATA_DIR}/${username}/nextcloud/do-not-erase-me-you-brake-nextcloud.txt
        
        sudo mkdir -p ${DATA_DIR}/${username}/data/Films
        sudo mkdir -p ${DATA_DIR}/${username}/data/SeriesTV
        sudo mkdir -p ${DATA_DIR}/${username}/data/Logiciels
        sudo mkdir -p ${DATA_DIR}/${username}/data/Documentaires
        sudo mkdir -p ${DATA_DIR}/${username}/data/Animes
        sudo mkdir -p ${DATA_DIR}/${username}/data/Musiques
        sudo mkdir -p ${DATA_DIR}/${username}/data/Livres

        sudo mkdir -p ${DATA_DIR}/${username}/config/filebrowser
        sudo touch ${DATA_DIR}/${username}/config/filebrowser/database.db

        sudo mkdir -p ${DATA_DIR}/${username}/config/torrent/custom_plugins
        sudo mkdir -p ${DATA_DIR}/${username}/config/torrent/.local/share/rtorrent
        sudo mkdir -p ${DATA_DIR}/${username}/config/torrent/run/rtorrent

        sudo mkdir -p ${DATA_DIR}/${username}/config/filerun
        sudo mkdir -p ${DATA_DIR}/${username}/config/filerun/{html,db}

        sudo mkdir -p ${DATA_DIR}/${username}/config/nextcloud

        sudo mkdir -p ${DATA_DIR}/${username}/config/sabnzbd

        sudo mkdir -p ${DATA_DIR}/${username}/config/pyload

        sudo mkdir -p ${DATA_DIR}/${username}/config/flaresolverr

        # Apply Rights
        echo "Applications des droits spécifiques pour un fonctionnement parfait entre nextcloud et la seedbox"
        sudo chown root:root ${DATA_DIR}/${username}
        sudo chmod 0770 ${DATA_DIR}/${username}/data
        sudo chmod -R 775 ${DATA_DIR}/${username}/data/
        sudo chmod 0770 ${DATA_DIR}/${username}/nextcloud
        sudo chmod -R 770 ${DATA_DIR}/${username}/nextcloud/
        sudo chmod -R 775 ${DATA_DIR}/${username}/config
        sudo chown -R $(whoami):www-data ${DATA_DIR}/${username}/data
        sudo chown -R $(whoami):www-data ${DATA_DIR}/${username}/nextcloud
        sudo chown -R $(whoami):www-data ${DATA_DIR}/${username}/config
    fi
}

function addToFTP {
docker exec -i pure_ftp /bin/bash << EOF
    ( echo ${password} ; echo ${password} )|pure-pw useradd ${username} -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -g www-data -d /home/ftpusers/${username}/data
EOF
}

function addToSFTP {
  echo "${username}:${password}:${MYUID}:${APACHEGID}" >> sftp/users.conf
}

function adduser {
  if [ ! -d ${DATA_DIR}/${username} ]
  then
    cp docker-compose/default docker-compose/${username}.yml
    htpasswd -b ${PASSWD_FILE} ${username} ${password}
    addToFTP
    addToSFTP
    createDisk
    getUtils
  fi
}

function checkLVMDiskStatus {
  sudo mount -av
  if [ $? -eq 0 ];then
    echo "Les disques sont montés correctement"
  else
    echo "Fatal error ! Check your LVM system ( fstab + mount -av ) . Something went wront !"
    exit 1
  fi
}

function createDisk {
  if [ "${LVM_STATUS}" = "yes" ]; then
    # Lvm Process
    echo "Starting LVM process..."
    checkLVMDiskStatus
    lvcreate -V ${diskSize}G --thin -n ${username} ${LVM_VG_NAME}/${LVM_POOL_NAME}
    mkdir -p ${DATA_DIR}/${username}
    mkfs.ext4 /dev/${LVM_VG_NAME}/${username}
    sudo echo "/dev/${LVM_VG_NAME}/${username} ${DATA_DIR}/${username}   ext4    defaults,discard,nofail        0       2" >> /etc/fstab
    sudo mount -av
    if [ $? -eq 0 ];then
      echo "The disk has been created successfully for ${username}"
    else
      echo "Fatal error ! Check your LVM system ( fstab + mount -av ) . Something went wront !"
      exit 1
    fi
    # End Lvm Process
  fi
  createDefaultDirectory
}

function modifyTemplateOfUser {
    cp dockers/${appSearched}/${appSearched}.yml dockers/${appSearched}/${appSearched}.yml.${username}.temp
    sed -i "s/{{ user }}/${username}/g" dockers/${appSearched}/${appSearched}.yml.${username}.temp
    sed -i "/# start services/ r dockers/${appSearched}/${appSearched}.yml.${username}.temp" "docker-compose/${username}.yml"
    rm -f dockers/${appSearched}/${appSearched}.yml.${username}.temp    
}