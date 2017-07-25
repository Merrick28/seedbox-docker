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
  echo "./seedbox.sh (ou seedbox.sh -a start) => lancement de la seedbox"
  echo "./seedbox.sh -a stop => arrête la seedbox"
  echo "./seedbox.sh -h => affiche l'aide"
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
########################################
# On détermine l'action
ACTION=start # Action par défaut
while getopts ":ha:" opt; do
  case $opt in
    a)
      ACTION=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

case $ACTION in
  start)
    start
    exit 0
    ;;
  stop)
    stop
    exit 0
    ;;
  *)
    echo "Action $ACTION non définie (doit être start ou stop)"
    exit 1
    ;;
esac

#start
