#!/bin/bash

if [ ! -f ./vars ]; then
echo "Le fichier vars n'a pas été trouvé"
echo "Vous devez copier le fichier vars-default en vars"
echo "Puis l'éditer selon vos besoins"
exit 1
else
    source ./vars
    export COMPOSE_IGNORE_ORPHANS=True
fi
# Test des variables
for myvar in BASE_URL ADMIN_URL PASSWD_FILE CF_API_EMAIL CF_API_KEY\
 CONFIG_DIR DATA_DIR PORTAINER_URL RUTORRENT_BASE_URL MEDUSA_BASE_URL COUCHPOTATO_BASE_URL\
 RADARR_BASE_URL JACKETT_BASE_URL BAZARR_BASE_URL SONARR_BASE_URL FLOOD_BASE_URL FILEBROWSER_BASE_URL\
 NEXTCLOUD_BASE_URL PLEX_URL JELLYFIN_URL TZ LVM_STATUS LVM_VG_NAME LVM_MAPPER
do
    if [ -z "${!myvar}" ]; then
    echo "La variable $myvar n'a pas été renseignée"
    echo "Vérifiez votre fichier vars avant de continuer"
    exit 1
    fi
done
