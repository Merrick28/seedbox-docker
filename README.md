# seedbox-docker
Une seedbox multi utilisateur (presque) prête à lancer, avec docker-compose

Tous les services sont lancés via docker, et rien n'est installé sur le serveur.

## Prérequis
- une machine linux connectée à Internet, avec deux noms de domaine (un pour les services utilisateurs, un pour l'administration).
- docker et docker-compose
- assez d'espace disque
- un utilisateur (non root) faisant partie du groupe docker

## Optionnel (mais recommandé)
- LVM pour gérer facilement les quotas
- htpasswd (fait partie du package apache2-utils sous debian/ubuntu)

## Fonctionnement

Un fichier docker-compose va faire un pull de toutes les images nécessaires et les lancer. Les entrées sorties vers les principales images sont gérées par [traefik](https://traefik.io/)

Ce projet utilise les images suivantes :
- [xataz/rtorrent-rutorrent](https://hub.docker.com/r/xataz/rtorrent-rutorrent/) : rtorrent et rutorrent
- [xataz/sickrage](https://hub.docker.com/r/xataz/sickrage/) : sickrage
- [traefik](https://traefik.io/) : pour gérer les I/O web
- [portainer/portainer](https://hub.docker.com/r/portainer/portainer/) : GUI pour manipuler les dockers
- [stilliard/pure-ftpd:hardened](https://github.com/stilliard/docker-pure-ftpd) pour les accès ftp

Traefik va également gérer automatiquement les certificats https pour les front end web.

## Lancement

Fait un git clone 
```
git clone https://github.com/Merrick28/seedbox-docker.git
cd seedbox-docker
```

### Préparation des mots de passe

Pour le premier utilisateur, lancer la commande
```
htpasswd -c passwd <mon_user>
```
Cela va créer le fichier passwd, et préparer un password chiffré

### Modifier le fichier seedbox.sh

Les variables à modifier sont :
- BASE_URL : URL de base pour les services (par exemple seedbox.mondomaine.net)
- ADMIN_URL : l'url d'administration (par exemple admin.mondomaine.net)
- MAIL_ADDRESS : adresse mail de contact pour letsencrypt.
