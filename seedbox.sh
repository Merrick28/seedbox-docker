#!/bin/bash
######################################
# Ce script va charger les variables 
# d'environnement nécessaires
# puis lancer le docker-compose up -d
######################################
# DEFINITION DES VARIABLES
# ====================================
# Url de base
# Les sites seront accessibles par
# https://BASE_URL/xxx
export BASE_URL=sb2.sdewitte.net
# URL pour Traefik
export ADMIN_URL=traefik.sdewitte.net
# Fichier de password
export PASSWD_FILE=./passwd
# Adresse mail de contact 
# (pour les certificats letsencrypt)
export MAIL_ADDRESS=stephane.dewitte@gmail.com
# Dossier de configuration
# Va recevoir la configuration de la seedbox 
# Concerne la configuration globale (hors utilisateur)
export CONFIG_DIR=/home/steph/config-seedbox
# Dossier utilisateurs
# Chaque utilisateur aura un dossier sous ce dossier
export DATA_DIR=/home/steph/data-seedbox
##########################
# Ne touchez à rien après cette ligne
##########################
# Définition des fonctions
function start {
  docker-compose $(for file in `ls *yml`;do echo "-f $file";done) up -d
}
function stop {
  docker-compose $(for file in `ls *yml`;do echo "-f $file";done) down
}
function usage {
  echo "Seedbox"
  echo "-------------------------"
  echo "Usage : "
  echo "./seedbox.sh (ou seedbox.sh --start) => lancement de la seedbox"
  echo "./seedbox.sh --stop => arrête la seedbox"
  echo "./seedbox.sh --restart => redémarre la seedbox"
  echo "./seedbox.sh --help => affiche l'aide"
  echo "./seedbox.sh --adduser toto => crée l'utilisateur toto"
}
function adduser() {
  username=$1
  echo "Ajout de l'utilisateur $1"
  if [ -f $username.yml ]
  then
    echo "#############################"
    echo "# Utilisateur déjà existant #"
    echo "#############################"
    echo "# Si vous voulez le recréer "
    echo "# Merci de le supprimer avant"
    exit 1
  else
    echo "Entrez son password, suivi de entrée"
    read mypassword
    echo "Enregistrement du password"
    htpasswd -b ./passwd $username $mypassword
    # recherche du port à ouvrir pour rutorrent
    declare -i myport
    myport=45001
    for file in `ls *yml`
    do
      current_port=$(grep UserPort $file | awk -F ':' '{print $1}'| awk -F '"' '{print $2}')
      if [ ! -z "$current_port" ]
      then
        if (( $current_port >= $myport ))
        then
          myport=$(( current_port + 1 ))
        fi
      fi
    done
    echo "Le port pour rutorrent sera le $myport"
    sed "s/{{ user }}/${username}/g" user.template | sed "s/{{ port }}/${myport}/g" > $username.yml
    echo "Lancement des dockers pour l'utilisateur ${username}"
    docker-compose -f $username.yml up -d
    echo "Ajout de l'utilisateur pour le FTP"
    docker exec -i pure_ftp_seedbox /bin/bash << EOF
( echo ${mypassword} ; echo ${mypassword} )|pure-pw useradd $username -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -d /home/ftpusers/$username/data 
EOF
  echo "Lancement des containers"
  docker-compose -f $username.yml up -d
  fi

}
#######################################
# Variables
export MYUID=$(id -u)
export MYGID=$(id -g)
# Gestion de password
for line in $(cat ${PASSWD_FILE})
do
  user=$(echo $line | awk -F':' '{print $1}')
  pass=$(echo $line | awk -F':' '{print $2}')
  export passwd_${user}=${pass}
done
OPTS=`getopt -o vhns: --long start,stop,restart,help,adduser: -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"
while true ; do
  case "$1" in
    --useradd)
      case "$2" in
        "") ARG_A='some default value' ; shift 2 ;;
        *) ARG_A=$2 ; shift 2 ;;
      esac ;;
    --start) 
      echo "Démarrage de la seedbox"
      echo "----------------------------------"
      start
      exit 0
      ;;
    --stop)
      stop
      exit 0
      ;;
    --restart)
      stop
      start
      exit 0
      ;;
    --help)
      usage
      exit 0
      ;;        
    --adduser)
      echo "Ajout de l'utilisateur $2"
      adduser $2
      exit 0
      ;;
      --) shift ; break ;;
      *) echo "Internal error!" ; exit 1 ;;
  esac
done

#start
