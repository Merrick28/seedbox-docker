#!/bin/bash



# Functions 
source includes/local_variables.sh
source includes/set_app.sh
source includes/help.sh
source includes/user_process.sh
source includes/specific_app.sh
source includes/seedbox_functions.sh
source includes/init.sh
source includes/utils.sh
source includes/vpn.sh
source includes/restart.sh
# End Functions

# Load Password & UID
getUtils
# End Load Password & UID

# Load Menu
OPTS=`getopt -o a?d:f?h?v?r? --long apps,delete:,help,version,recreate-base-system,stop,start,restart,seedbox:,all-seedbox,delete-data,delete-config,delete-all,first-install,username:,password:,diskSize:,radarr:,lidarr:,sonarr:,medusa:,jackett:,bazarr:,rutorrent:,flood:,filebrowser:,nextcloud:,filerun:,sabnzbd:,pyload:,flaresolverr:,readarr:,vpn,create-client-no-password:,create-client-with-password:,view-all-client,remove-client: -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

while test "$1" != --; do
  case "$1" in
    -a | --apps )
        username="$2"
        shift 1
        while test "$1" != --; do
            case "$1" in
                -u | --username )
                    username="$2"  
                    if [ ! -z "${username}" ] && [ "${username}" != "--" ] ; then                  
                        shift 2
                    else
                        echo "Forced to exit ! Do not retry !"
                        exit 1
                    fi
                    ;;
                -p | --password )
                    password="$2";
                    if [ ! -z "$password" ]; then
                        shift 2
                    else
                        echo "Password is empty..."
                        exit 1
                    fi                    
                    ;;
                --diskSize )    
                    diskSize="$2"
                    if [[ "$diskSize" =~ ^[0-9]+$ ]]; then
                        adduser
                        shift 2
                    else
                        echo "diskSize is incorrect..."
                        exit 1
                    fi
                    ;;
                --radarr ) 
                    set_radarr="$2"
                    setDesiredStatusOfApp radarr $set_radarr
                    shift 2
                    ;;
                --lidarr ) 
                    set_lidarr="$2"
                    setDesiredStatusOfApp lidarr $set_lidarr
                    shift 2
                    ;;
                --sonarr ) 
                    set_sonarr="$2"
                    setDesiredStatusOfApp sonarr $set_sonarr
                    shift 2
                    ;;
                --medusa ) 
                    set_medusa="$2"
                    setDesiredStatusOfApp medusa $set_medusa
                    shift 2
                    ;;
                --jackett ) 
                    set_jackett="$2"
                    setDesiredStatusOfApp jackett $set_jackett
                    shift 2
                    ;;
                --bazarr ) 
                    set_bazarr="$2"
                    setDesiredStatusOfApp bazarr $set_bazarr
                    shift 2
                    ;;
                --rutorrent ) 
                    set_rutorrent="$2"
                    setDesiredStatusOfApp rutorrent $set_rutorrent
                    shift 2
                    ;;
                --flood ) 
                    set_flood="$2"
                    setDesiredStatusOfApp flood $set_flood
                    shift 2
                    ;;
                --filebrowser ) 
                    set_filebrowser="$2"
                    setDesiredStatusOfApp filebrowser $set_filebrowser
                    shift 2
                    ;;
                --filerun ) 
                    set_filerun="$2"
                    setDesiredStatusOfApp filerun $set_filerun
                    shift 2
                    ;;
                --nextcloud ) 
                    set_nextcloud="$2"
                    setDesiredStatusOfApp nextcloud $set_nextcloud
                    shift 2
                    ;;
                --sabnzbd ) 
                    set_sabnzbd="$2"
                    setDesiredStatusOfApp sabnzbd $set_sabnzbd
                    shift 2
                    ;;
                --pyload ) 
                    set_pyload="$2"
                    setDesiredStatusOfApp pyload $set_pyload
                    shift 2
                    ;;
                --flaresolverr ) 
                    set_flaresolverr="$2"
                    setDesiredStatusOfApp flaresolverr $set_flaresolverr
                    shift 2
                    ;;
                --readarr ) 
                    set_readarr="$2"
                    setDesiredStatusOfApp readarr $set_readarr
                    shift 2
                    ;;
                -- ) 
                    shift; 
                    break 
                    ;; 
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        checkIfRebootNeeded
        ;;
    --stop )
        shift 1
        while test "$1" != --; do
            case "$1" in
                --seedbox )
                    username="$2"
                    actionSeedbox stop
                    shift 2
                    ;;
                --all-seedbox )
                    actionAllSeedbox stop
                    shift 1
                    ;;
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        ;;
    --start )
        shift 1
        while test "$1" != --; do
            case "$1" in
                --seedbox )
                    username="$2"
                    actionSeedbox start
                    shift 2
                    ;;
                --all-seedbox )
                    actionAllSeedbox start
                    shift 1
                    ;;
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        ;;
    --restart )
        shift 1
        while test "$1" != --; do
            case "$1" in
                --seedbox )
                    username="$2"
                    actionSeedbox stop
                    actionSeedbox start
                    shift 2
                    ;;
                --all-seedbox )
                    actionAllSeedbox stop
                    actionAllSeedbox start
                    shift 1
                    ;;
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        ;;
    -d | --delete )
        username="$2"
        shift 2
        while test "$1" != --; do
            case "$1" in
                --delete-data )
                    actionSeedbox stop
                    deleteData
                    createDefaultDirectory
                    actionSeedbox start
                    shift 1
                    ;;
                --delete-config )
                    actionSeedbox stop
                    deleteConfig
                    createDefaultDirectory "reset"
                    actionDockerComposeSeedbox $username up
                    shift 1
                    ;;
                --delete-all )
                    deleteRecordInDomain
                    actionSeedbox stop
                    actionSeedbox rm                    
                    deleteDockerComposeFile
                    deleteFromPasswd
                    deleteFromPureFTP
                    deleteFromSFTP
                    deleteHomeUser
                    shift 1
                    ;;
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        ;;
    --vpn )
        shift 1
        while test "$1" != --; do
            case "$1" in
                --first-install )
                    vpnInstallation
                    shift 1
                    ;;
                --create-client-no-password )
                    client_name="$2"
                    createVPNClientWithoutPassword
                    exportVPNClient
                    shift 2
                    ;;
                --create-client-with-password )
                    client_name="$2"
                    createVPNClientWithPassword
                    exportVPNClient
                    shift 2
                    ;;
                --view-all-client )
                    viewAllVPNClient
                    shift 1
                    ;;
                --remove-client )
                    client_name="$2"
                    removeVPNClient
                    deleteVPNClientFile
                    shift 2
                    ;;
                --delete-all )
                    deleteAll
                    shift 1
                    ;;
                * ) echo "Unexpected option: $1 - this should not happen."
                    showHelp
                    break
                    ;;
            esac
        done
        ;;
    -f | --first-install )
        firstInitialisation
        shift 1
        break
        ;;
    -r | --recreate-base-system )
        recreateIfNeededBaseSystem
        shift 1
        break
        ;;
    -h | --help )
        showHelp
        break
        ;;
    -v | --version )
        echo "v5.0"
        break
        ;;
    -- ) shift;
        break
        ;;
    * ) echo "Unexpected option: $1 - this should not happen."
        showHelp
        break
        ;;
  esac
done
# End Load Menu
