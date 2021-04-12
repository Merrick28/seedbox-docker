#!/bin/bash

function addBaseSystemToDNS {
    cd ansible || exit 1
    ansible-playbook -i hosts site.yml
    cd ..
}

function createDefaultDirectoryBase {
  mkdir -p {${DATA_DIR},${CONFIG_DIR}}
  sudo chown root:root ${DATA_DIR}
  mkdir -p "${CONFIG_DIR}/traefik/provider"
  mkdir ${CONFIG_DIR}/netdata
  mkdir ${CONFIG_DIR}/netdata/{cache,config,lib}
  chmod -R 775 ${CONFIG_DIR}/netdata
  sudo chown -R 201:201 ${CONFIG_DIR}/netdata
}

function firstInitialisation {
    if groups ${USER} | grep &>/dev/null '\bdocker\b'; then
    :
    else
        echo "Erreur - Lancez la commande"
        echo "sudo usermod -aG docker ${USER}"
        echo "Puis déconnectez et reconnectez vous"
        exit 1
    fi

    # Create traefik network
    network=$(docker network ls --format "{{.Name}}" --filter name=traefik_proxy)
    if [ "$network" != "traefik_proxy" ]
    then
        createTraefikDockerNetwork
    fi


    if [ ! -f ${PASSWD_FILE} ]
    then
      createDefaultDirectoryBase
      addBaseSystemToDNS
      createAdmin      
      exit 0
    fi
    if ! grep -q admin ${PASSWD_FILE}
    then
      createDefaultDirectoryBase
      addBaseSystemToDNS
      createAdmin      
      exit 0
    else
        echo "L'installation a déja été réalisée..."
        exit 0
    fi
}

function createTraefikDockerNetwork {
    docker network create traefik_proxy
}

function createAdmin {

  echo "Saisissez le mot de passe du compte administrateur :"
  read adminpassword
  if [ ! -f ${PASSWD_FILE} ] 
  then
    htpasswd -bc ${PASSWD_FILE} admin ${adminpassword}
  else
    htpasswd -b ${PASSWD_FILE} admin ${adminpassword}
  fi
  getUtils
  generateKeysForSFTP
  docker-compose $(echo "-f docker-compose.yml";) up -d
  echo "Le compte admin a été créé."
  echo "Vous devez maintenant vous connecter sur https://${PORTAINER_BASE_URL}-${SERVER_BASE_URL}.${DOMAIN_URL}/ et choisir un mot de passe pour sécuriser la partie portainer"
  echo "Vous devez sélectionner la connexion avec Docker, si non proposé, voir Help README."

}

function generateKeysForSFTP {
  echo "Lancement de la génération des clés SFTP, laissez vide les champs..."
  mkdir -p sftp && cd sftp || exit 1
  touch users.conf
  ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
  ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
  cd ..
}
