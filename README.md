# Attention
- Faites des backups/snapshots avant de lancer le script !
Vous risquez de produire des erreurs de frappes qui feront planter le script...

- La version >= 5 n'a aucun rapport avec la version 2 précedente. Pas d'upgrade simple possible.
# Présentation du script

Le script est adapté à **Debian 10**. De trés minimes adaptations peuvent être nécessaires pour fonctionner sous Ubuntu... Testez, retestez ! et proposez une PR !

Le script a été pensé par son fondateur @Merrick28 pour être le moins ancré dans le système principal.
Par conséquent, le seul utilisateur du système est celui que vous allez créer dans les prochaines étapes. Peu importe le nombre de seedbox que vous allez gérer, il n'y aura pas plus d'utilisateurs système !

Le déploiement des seedbox est géré par du scripting Bash et par Ansible pour la partie DNS et sécurisation minimale du serveur.

Aucune application n'est installée en dur sur le système. Par conséquent, aucune raison ne devrait vous empecher un passage de Debian 10 à 11 par exemple.

Traefik V2.4 est utilisé en tant que reverse proxy. DockerCompose V3.9 est de la partie pour le déploiement des applications.
La version 5 du script apporte de **la modularité** pour chaque seedbox, en installant uniquement certaines applications pour certaines seedbox.
De nouvelles applications sont disponibles à l'installation, et ont été testées complétement !
Certaines applications n'ont pas d'authentification de traefik lors de l'accès car cela empêchait dans certains cas la communication avec d'autres applications.
L'aspect fonctionnalité a été privilégié.

# Sécurisation
- Mises à jour automatiques de sécurité tous les jours, et redémarrage automatique à 5h00 si nécessaire pour l'application de la mise à jour.
- Envoi de mail automatique lors de mises à jours nocturnes...
- LogWatch, envoi de mail journalier récapitulant les différentes tentatives de connexions infructueuses.
- Sécurisation des accès SSH par Fail2ban, politique de restriction stricte.
- Utilisation de RkHunter pour détecter les Rootkits, portes dérobées et exploits au sein du système.
- (A revoir, laissé en commentaire) Mise en place de règles Iptables

-> Proposez des PR avec encore plus de sécurisation, en particulier au niveau des ports / règles iptables !

# Configuration des variables
Copier le fichier vars-default en vars puis modifier le fichier selon votre besoin.

Copier le fichier ansible/group_vars/all-default.yml en ansible/group_vars/all.yml puis modifier le fichier selon votre besoin.

# LVM & Système de fichiers
Ce script est pensé pour être utilisé avec un système `LVM ou non`.
Les deux fonctionnent sans problème, mais le LVM est à privilégier car il apporte une plus grande souplesse.
Le LVM utilisé ici est du LVM Thin (avec pool) permettant l'over-provisioning. C'est à vous de le monitorer si vous voulez sur provisionner.

Si vous ne souhaitez pas utiliser le système LVM, il suffit pour cela de mettre `LVM_STATUS=no`. Le script s'occupera alors de créer les répertoires utilisateurs en dessous de `$DATA_DIR`.
Si vous n'avez pas créer d'espace disque en dur, alors tous les utilisateurs partageront la même capacité de disque.

Si vous souhaitez utiliser le système LVM, alors définissez la variable à `LVM_STATUS=yes` en indiquant les différentes autres valeurs pour indiquer au script quel est le nom de votre VG `LVM_VG_NAME` et votre pool `LVM_POOL_NAME` **que vous aurez préalablement crée manuellement !**



## DNS & Cloudflare

Ce script est pensé pour être utilisé avec les APIs de Cloudflare uniquement.
Il est nécessaire de remplir les variables d'environnement du fichier `seedbox-docker/ansible/group_vars/all.yml` avec vos données.
Le script s'occupe de créer automatiquement les enregistrements DNS pour votre système de base, mais aussi lors de l'ajout d'utilisateurs.
Le proxy Cloudflare est activé lorsqu'il est possible de l'utiliser ( dans la majorité des cas ).
CloudFlare version gratuite ne permet pas la réalisation de domaine du type : `sousdomaine.sousdomaine.domaine.fr` avec l'obtention d'un certificat wildcard.
Par conséquent, regardez attentivement le vars-default.

# Si vous souhaitez effectuer des tests avant une future installation, il est recommandé d'utiliser le serveur de test de Let's Encrypt pour éviter d'atteindre le nombre maximale de requêtes possibles.

Pour cela ajouter cette ligne : `- "--certificatesResolvers.mydnschallenge.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"` sous `# Certificate Resolver` dans le fichier docker-compose.yml

# Avant de lancer le script

En root :

`hostnamectl set-hostname serveur.domain.fr`

Dans `/etc/hosts` : `serveur.domain.fr serveur`

Création d'un utilisateur : `adduser monuser`

Dans `/etc/sudoers` : `monuser ALL=(ALL) NOPASSWD:ALL`

`chmod -R 775 seedbox-docker`

`chown -R monuser:monuser seedbox-docker`

# Installation de Docker (en root/sudo)

Suivre la procédure officielle : https://docs.docker.com/engine/install/debian/

La commande `docker -v` doit vous renvoyer la version de Docker.

# Installation de Docker-Compose (en root/sudo)

Suivre la procédure officielle : https://docs.docker.com/compose/install/

La commande `docker-compose -v` doit vous renvoyer la version de Docker-Compose.

# Ajout de notre utilisateur au groupe Docker
`usermod -aG docker monuser`

Il est recommandé de se déconnecter puis se reconnecter du SSH dans le but d'appliquer le changement de groupe.

# Installation de paquets pour Debian 10
`sudo apt-get install apache2-utils python3 python3-pip`
`pip3 install ansible`

`ansible --version | grep "python version"`
-> Doit renvoyer au minimum : python version = 3.7.3 (default, Jan 22 2021, 20:04:44) [GCC 8.3.0]

`ansible --version | grep "python version"`
-> Doit renvoyer a minima : python version = 3.7.3 (default, Jan 22 2021, 20:04:44) [GCC 8.3.0]

`ansible --version`
-> Doit renvoyer a minima : ansible 2.10.7

# Si LVM=yes 
Vous devez créer votre VG et votre Pool.

Exemple Partiel : 
```
umount /home
vgcreate vg_home /dev/sda2
lvcreate -l 100%FREE --thinpool pool_0_vg_home vg_home
```

# Lancement du script de sécurisation minimale
```
cd seedbox-docker/ansible
ansible-playbook secure.yml -i hosts
```
# Lancement de la première installation
```
cd seedbox-docker
./seedbox_system.sh -f
```
# Ajout d'un utilisateur
Mettre le diskSize à un nombre aléatoire si non utilisation de LVM ou si l'utilisateur a déja été crée.
Nextcloud a besoin d'un mot de passe de 6 caractères au minimum !

`./seedbox_system -a --username toto --password totopassword --diskSize 400 --rutorrent yes --flood yes`

# Suppression d'un utilisateur (strictement tout, lvm compris si existant)

`./seedbox_system -d toto --delete-all`

# Help
`./seedbox_system -h`

# Version
`./seedbox_system -v`

# FTP et SFTP
FTP : Port 21 -> Mode de transfert : Actif
SFTP : Port 2222

# Améliorer le projet
Toute amélioration est la bienvenue ! Merci de tester au maximum vos modifications pour vérifier qu'elles n'ont pas d'impact sur les droits d'une autre application par exemple.

# A améliorer :
- Le menu impose de saisir le diskSize même lorsque cela n'est pas nécessaire
- Mettre en place des règles iptables avec Ansible
- Chrooter le SFTP au même niveau que le FTP sans avoir de conséquences sur les applications (ex: nextcloud)
- ....

# Help :

## Mes enregistrements DNS ne se font pas, Ansible plante !
La première chose à faire est de vérifier **les deux** fichiers de variables d'environnements.
Ensuite, il faut vérifier les droits que vous avez attribué au niveau du Token de Cloudflare.

Partie : Jetons API :
Zone.Réglages Zone, Zone.Zone, Zone.DNS 

## Portainer ne voit pas mes conteneurs
Si vous êtes trés rapide pour vous connecter, Portainer n'aura pas le temps de se connecter au socket Docker. Pour résoudre le problème, créer votre compte sur Portainer, puis déconnectez vous et reconnectez vous. Il vous proposera ensuite de sélectionner **"Docker - Manage the local Docker environment"**. Cliquez sur connect, et voilà !

## Mon hebergeur m'indique que PLEX/Jellyfin/... surcharge de log son firewall
Dans la configuration de PLEX il faut désactiver le GDM (local network discovery) et le DLNA. Sinon le serveur va polluer tout le réseau de l'hébergeur..

# Version applicatives testées et fonctionnelles, dernières en date au (24/03/2021)
Traefik : 2.4.8
Portainer : 2.1.1
Rutorrent : latest
flood : 4.5.0
...
