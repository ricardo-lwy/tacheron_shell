#!/bin/bash

#tacherontab [-u user] {-l | -r | -e}
if [ "$1" == '-u' ]
then
    userName=$2
    case $3 in
    -l) cat "/etc/tacheron/${userName}";;
    -r) rm "/etc/tacheron/${userName}";;
    -e) vi "/etc/tacheron/${userName}";;
    *)
        echo "erreur command ";;
    esac
else

#tacherontab –u toto -l affiche le fichier
#tacherontab de l'utilisateur toto situé dans le répertoire /etc/tacheron/
#tacherontab –u toto -r efface le fichier
#tacherontab de l'utilisateur toto
#tacherontab –u toto -e crée ou édite (pourmodification) un fichier temporaire dans /tmp ouvertdans vi. 
#Lors de la sauvegarde, le fichier est écrit dans /etc/tacheron/tacherontabtoto.
    case $1 in
    -l) cat /etc/tacherontab;;
    -r) rm /etc/tacherontab;;
    -e) vi /etc/tacherontab;;
    *)
        echo "erreur command ";;
    esac
fi
