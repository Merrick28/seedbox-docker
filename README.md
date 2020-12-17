# seedbox-docker
Une seedbox multi utilisateur (presque) prête à lancer, avec docker-compose

Tous les services sont lancés via docker, et rien n'est installé sur le serveur.

# ATTENTION

Passage en traefik v2.
Si vous aviez déjà ce produit sur les versions précédentes, pour mise à jour :
- stopper la seedbox (./seedbox.sh --stop)
- copiez le fichier des passwords dans un endroit sur (par défaut passwd)
- Supprimez tous les utilisateurs via la commande ./seedbox.sh en iteractif
- Faites un git pull pour mettre le repo à jour
- Recréez tous les utilisateurs via la commande ./seedbox.sh en mode interactif
- Relancez le tout avec la commande ./seedbox.sh --restart


## Prérequis
- une machine linux connectée à Internet, avec deux noms de domaine (un pour les services utilisateurs, un pour l'administration).
- docker et docker-compose
- assez d'espace disque
- un utilisateur (non root) faisant partie du groupe docker
- htpasswd (fait partie du package apache2-utils sous debian/ubuntu)

## Optionnel (mais recommandé)
- LVM pour gérer facilement les quotas

## Fonctionnement

Des fichiers docker-compose vont faire un pull de toutes les images nécessaires et les lancer. Les entrées sorties vers les principales images sont gérées par [traefik](https://traefik.io/)

Ce projet utilise les images suivantes :
- [traefik](https://traefik.io/) : pour gérer les I/O web
- [xataz/rtorrent-rutorrent](https://hub.docker.com/r/xataz/rtorrent-rutorrent/) : rtorrent et rutorrent
- [xataz/sickrage](https://hub.docker.com/r/xataz/sickrage/) : sickrage
- [xataz/medusa](https://hub.docker.com/r/xataz/medusa/) : medusa
- [xataz/couchpotato](https://hub.docker.com/r/xataz/couchpotato/) : couchpotato (l'image est modifiée pour ajouter unrar)
- [portainer/portainer](https://hub.docker.com/r/portainer/portainer/) : GUI pour manipuler les dockers
- [stilliard/pure-ftpd:hardened](https://github.com/stilliard/docker-pure-ftpd) pour les accès ftp
- [mwader/postfix-relay](https://hub.docker.com/r/mwader/postfix-relay/) pour l'envoi des mails en utilisant le DKIM

Traefik va également gérer automatiquement les certificats https pour les front end web, et rediriger les flux http en https.

## Documentation

Toute la documentation se trouve dans [le wiki](https://github.com/Merrick28/seedbox-docker/wiki)

