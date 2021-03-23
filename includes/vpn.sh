#!/bin/bash
function vpnInstallation {
    check_vpn_install=`docker ps | grep openvpn > /dev/null; echo $?`
    if [ $check_vpn_install -ne 0 ]; then
        cd openvpn || exit 1
        mkdir -p ${CONFIG_DIR}/openvpn/{client-vpn,openvpn-data}
        docker-compose run --rm openvpn ovpn_genconfig -u udp://${VPN_BASE_URL}-${BASE_URL}
        if [ $? -eq 0 ]; then
            docker-compose run --rm openvpn ovpn_initpki
            if [ $? -eq 0 ]; then
            sudo chown -R ${MYUID}:${MYGID} ${CONFIG_DIR}/openvpn
            docker-compose up -d openvpn
            echo "The VPN is configured, you can now create your config files."
            else
                deleteAll
                echo "An error occured, the process --delete-all has been executed"
                exit 1
            fi
        else
            deleteAll
            echo "An error occured, the process --delete-all has been executed"
            exit 1
        fi
        cd ..
    else
        echo "Le VPN est déja installé"
    fi
}

function createVPNClientWithoutPassword {
    cd openvpn || exit 1
    docker-compose run --rm openvpn easyrsa build-client-full "ovpn-"${client_name} nopass
    cd ..
}

function createVPNClientWithPassword {
    cd openvpn || exit 1
    docker-compose run --rm openvpn easyrsa build-client-full "ovpn-"${client_name}
    cd ..
}

function viewAllVPNClient {
    cd openvpn || exit 1
    docker-compose run --rm openvpn ovpn_listclients
    cd ..
}

function removeVPNClient {
    cd openvpn || exit 1
    docker-compose run --rm openvpn ovpn_revokeclient "ovpn-"${client_name} remove
    cd ..
}

function exportVPNClient {
    cd openvpn || exit 1
    docker-compose run --rm openvpn ovpn_getclient "ovpn-"${client_name} > ${CONFIG_DIR}/openvpn/client-vpn/"ovpn-"${client_name}.ovpn
    echo "The configuration has been exported to : " ${CONFIG_DIR}/openvpn/client-vpn/"ovpn-"${client_name}.ovpn
    cd ..
}

function deleteVPNClientFile {
    if [ -f ${CONFIG_DIR}/openvpn/client-vpn/"ovpn-"${client_name}.ovpn ]; then
        rm -f ${CONFIG_DIR}/openvpn/client-vpn/"ovpn-"${client_name}.ovpn
    fi
}

function deleteAll {
    docker stop openvpn
    docker rm openvpn
    sudo rm -rf ${CONFIG_DIR}/openvpn
}