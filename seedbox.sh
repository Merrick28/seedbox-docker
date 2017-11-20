#!/bin/bash
######################################
# Ce script va charger les variables 
# d'environnement nécessaires
# puis lancer le docker-compose up -d
if [ ! -f ./vars ]; then
    echo "Le fichier vars n'a pas été trouvé"
    echo "Vous devez copier le fichier vars-default en vars"
    echo "Puis l'éditer selon vos besoins"
    exit 1
else
    source ./vars
fi
# test des variables
for myvar in BASE_URL ADMIN_URL PASSWD_FILE MAIL_ADDRESS CONFIG_DIR DATA_DIR
do
    if [ -z "${!myvar}" ]; then
      echo "La variable $myvar n'a pas été renseignée"
      echo "Vérifiez votre fichier vars avant de continuer"
      exit 1
    fi

done
##########################
# Définition des fonctions
##########################
# Start
function start {
  docker-compose $(for file in `ls *yml`;do echo "-f $file";done) up -d
}
# stop
function stop {
  docker-compose $(for file in `ls *yml`;do echo "-f $file";done) down
}
# usage
function usage {
  echo "Seedbox"
  echo "-------------------------"
  echo "Usage : "
  echo "./seedbox.sh => lancement en interactif"
  echo "./seedbox.sh --start => lancement de la seedbox"
  echo "./seedbox.sh --stop => arrête la seedbox"
  echo "./seedbox.sh --restart => redémarre la seedbox"
  echo "./seedbox.sh --help => affiche l'aide"
  echo "./seedbox.sh --adduser toto => crée l'utilisateur toto"
  echo "./seedbox.sh --deluser toto => supprime l'utilisateur toto (sans confirmation, les données sont conservées)"
  echo "./seedbox.sh --maj => met à jour tous les containers"
  echo "./seedbox.sh --help => affiche cette aide"
}
# deluser
function deluser() {
  username=$1
  echo "Suppression de l'utilisateur ftp"
  docker exec -i pure_ftp_seedbox /bin/bash << EOC 
    pure-pw userdel $username -f /etc/pure-ftpd/passwd/pureftpd.passwd
EOC
  echo "Suppression des fichiers de configuration"
  rm -f $username.yml
  echo "Suppression du fichier des mots de passe"
  htpasswd -D ${PASSWD_FILE} $username
  echo "Suppression de l'utilisateur terminée"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
  echo "Les dossiers de l'utilisateur ont été conservés"
  affiche_restart
}
# affiche_restart
function affiche_restart() {
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
  echo "IMPORTANT"
  echo "Vous devez redémarrer la seedbox pour appliquer les changements"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
}
# adduser
# prend en parametre le user à rajouter
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
    htpasswd -b ${PASSWD_FILE} $username $mypassword
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
    #echo "Le port pour rutorrent sera le $myport"
    sed "s/{{ user }}/${username}/g" user.template | sed "s/{{ port }}/${myport}/g" > $username.yml
    echo "Ajout de l'utilisateur pour le FTP"
    docker exec -i pure_ftp_seedbox /bin/bash << EOF
( echo ${mypassword} ; echo ${mypassword} )|pure-pw useradd $username -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -d /home/ftpusers/$username/data 
EOF
    echo "L'utilisateur a été créé."
    echo "Adresse de rutorrent : https://${BASE_URL}/${username}_rutorrent/"
    echo "Adresse de sickrage : https://${BASE_URL}/${username}_sickrage/"
    echo "Adresse de couchpotato : https://${BASE_URL}/${username}_couchpotato"
    affiche_restart
  fi
}
# maj => met à jour tous les containers
function maj {
    docker-compose $(for file in `ls *yml`;do echo "-f $file";done) pull
    affiche_restart
}
# create_admin
function create_admin {
  ###################################
  # Cette fonction ne va se lancer
  # que pour créer un admin
  echo "Vous n'avez pas encore de compte administrateur pour cette seedbox"
  echo "Il faut en créer un pour pouvoir continuer."
  echo "Saisissez le mot de passe du compte :"
  read adminpassword
  if [ ! -f ${PASSWD_FILE} ] 
  then
    htpasswd -bc ${PASSWD_FILE} admin $adminpassword
  else
    htpasswd -b ${PASSWD_FILE} admin $adminpassword
  fi
  export passwd_admin=${adminpassword}
  start
  echo "Le compte admin a été créé."
  echo "Vous devez maintenant vous connecter sur https://${ADMIN_URL}/portainer et choisir un mot de passe pour sécuriser la partie portainer"

}
function interactive {
  INTERACTIVE=1
  while [ 1 ]
    do
    CHOICE=$(
    whiptail --title "Seedbox docker" --menu "Faites votre choix" 16 100 9 \
        "1)" "Démarrer la seedbox."   \
        "2)" "Arrêter la seedbox."  \
        "3)" "Redémarrer la seedbox." \
        "q)" "Quitter cette interface"  3>&2 2>&1 1>&3
    )
    case $CHOICE in
        "1)")
            start
        ;;
        "2)")
            stop
        ;;

        "3)")
            whiptail --textbox /dev/stdin 16 100 9 <<< $(./seedbox.sh --stop)
            whiptail --textbox /dev/stdin 16 100 9 <<< $(./seedbox.sh --start)
        ;;



        "q)") exit
            ;;
    esac
    whiptail --msgbox "$result" 20 78
    done
  exit 0
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
INTERACTIVE=0 # on met le interactive à 0, on changera plus tard si besoin
#########################################
# On vérifie que le user est bien dans le groupe docker
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    :
else
    echo "#####################################"
    echo "ERREUR"
    echo "Votre utilisateur n'est pas dans le groupe docker"
    echo "Lancez la commande"
    echo "sudo usermod -aG docker $USER"
    echo "Puis déconnectez et reconnectez vous"
    exit 1
fi
#########################################
# Avant de passer à la suite, on va
# regarder s'il y a un admin
if [ ! -f ${PASSWD_FILE} ]
then
  create_admin
  exit 0
fi
if ! grep -q admin ${PASSWD_FILE}
then
  create_admin 
  exit 0
fi
#########################################
# Options de lancement
OPTS=`getopt -o vhns: --long start,stop,restart,help,maj,adduser:,deluser:,interactive -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"
while true ; do
  case "$1" in
    --interactive)
      interactive
      exit 0
      ;;
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
      adduser $2
      exit 0
      ;;
    --deluser)
      echo "Suppression de l'utilisateur $2"
      deluser $2
      exit 0
      ;;
    --maj)
      echo "Mise à jour des containers"
      maj
      exit 0
      ;;
      --) shift ; break ;;
      *) echo "Internal error!" ; exit 1 ;;
  esac
done

# On n'a passé aucun paramètre, on en déduit qu'il faut partir en interactif
interactive
