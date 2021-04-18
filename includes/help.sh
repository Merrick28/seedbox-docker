#!/bin/bash

function showHelp {
    echo -e "
    Available options are :

        [ -f | --first-install ]    : Install the basic system (parameter : NONE).

        [ -a | --apps ]             : Configuration of user applications (parameter : NONE).

                [ --username username ]      : Name of user.
                [ --password password ]      : Password of user.
                [ --diskSize 500 ]      : Amount of space for the disk (GB).

                List of available applications yes/no :
                
                [ --radarr ]
                [ --lidarr ]
                [ --sonarr ]
                [ --medusa ]
                [ --jackett ]
                [ --couchpotato ]
                [ --bazarr ]
                [ --rutorrent ]
                [ --flood ]
                [ --filebrowser ]
                [ --filerun ]
                [ --nextcloud ]
                [ --sabnzbd ]
                [ --pyload ]
                [ --flaresolverr ]


        [ -d | --delete username ]           : Delete functions (parameter : Name of user).
                
                [ --delete-data ]   : Delete data folders of user but keep configuration folders.
                [ --delete-config ] : Delete configuration folders of user but keep data folders.
                [ --delete-all ]    : Delete EVERYTHING about a user.
        
        [ --vpn ]                   : Configuration of vpn (parameter : NONE).
                
                [ --first-install ]                         : Install the VPN system within Docker.
                [ --create-client-no-password username]     : Create a client without password
                [ --create-client-with-password username]   : Create a client with password
                [ --view-all-client]                        : List of clients
                [ --remove-client username]                 : Remove a client
                [ --delete-all ]                            : Delete everything about the vpn


        [ -h | --help ]             : Display this help.

        [ -v | --version ] : Display the seedbox's version.

    Usage examples :

        Informations : 
            - If the user's app is installed and you put --appname no , it will uninstall it, but keep data and configuration file :).
            - You can uninstall each app of a user if needed.
            - Do not modify the docker-compose of user manually, you could brake it.

            - ./seedbox_system.sh -f
            
            - ./seedbox_system.sh -a --username myuser --password mypassword --diskSize 400 --radarr yes --rutorrent yes --flood yes
            - ./seedbox_system.sh -a --username myuser --password mypassword --diskSize 400 --filebrowser yes --rutorrent no

            - ./seedbox_system.sh -d myuser --delete-data --delete-config
            - ./seedbox_system.sh -d myuser --delete-all

            - ./seedbox_system.sh --vpn --first-install
            - ./seedbox_system.sh --vpn --create-client-no-password myuser
            - ./seedbox_system.sh --vpn --create-client-with-password myuser
            - ./seedbox_system.sh --vpn --delete-all


            - ./seedbox_system.sh -v

    "
}