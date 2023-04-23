#!/bin/bash



# Vérifier les autorisations des utilisateurs
if [ -f /etc/tacheron.allow ]       #si /etc/tacheron.allow exist

then   

    users_allow="${(cat /etc/tacheron.allow)} root" # Exécuter la liste des utilisateurs autorisés de tacheron

else
    users_allow='root'
fi


if [ -f /etc/tacheron.deny ]   #si /etc/tacheron.deny  exist
then
    while [read User_nautorises] # Lire les utilisateurs non autorisés
    do
        users_allow=(${users_allow[@]//${User_nautorises}})

    done < /etc/tacheron.deny
fi



if [ echo "${users_allow[@]}" | grep -Fq ${USER} ] # Trouver user dans la liste
then
    Creer_Tableaux /etc/tacherontab     # Lire le contenu et créer un tableau de commandes
    if [ -d /etc/tacheron/ ]
    then
        for name in `ls /etc/tacheron/`
        do
            Creer_Tableaux ${name}
        done
    fi
                              
    declare -A Tableau_tri  ##Définir une taille tridimensionnelle pour traiter le problème du jugement temporel
    total_length=0
    x=0

#Fonction pour écrire des données d'entrée dans un tableau
declare -a enter_list

Nb=0 ##Le nombre de membres dans le tableau

# traiter le fichier ou la phrase d'entrée dans le tableau enter_list
function Creer_Tableaux {

    while [read Line]   ## Lire le contenu d'entrée
    do
        enter_list[${Nb}]="${Line}" 
        Nb=`expr ${Nb} + 1` # Augmentation du nombre
    done < ${1}  


     ##Traitez les six premières données sur le temps
    for Line in "${enter_list[@]}" #Opérer sur chaque ligne du tableau
    do 
        for y in {0..5}
        do  
            #Intercepter le contenu de la ligne dans les blocs un par un
          
            headwords=${Line%% *} #Intercepter la chaine après le dernier espace de droite à gauche
            Line="${Line#* }" #Intercepter la chaine du premier espace de gauche à droite, qui est complémentaire du précédent

            #Si trouvé*
            if [echo "${headwords}" | grep -oF '*'] 
            then
                Tableau_tri[${x},${y},0]='*'
            else

                #Afin de correspondre aux deux méthodes de traitement du temps
                # 1. 1-6 et 2. 1,2,3,4,6 définir deux types de temps
                time_type1=`echo "${headwords}" | grep -oE '^[0-9]+'`
                time_type2=`echo "${headwords}" | grep -oE ',[0-9]+' | grep -oE '[0-9]+'`

                #Trier par nombre et supprimer les lignes en double
                Tableau_tri[${x},${y},0]="`echo -e "${time_type1}\n${time_type2}" | sort -nu`"  

                #Définir la plage horaire
                varRange=(`echo "${headwords}" | grep -oE '[0-9]+-[0-9]+'`)
                for range_item in "${varRange[@]}"
                do
                    for ((i=${range_item%-*};i<=${range_item#*-};i++));do
                        Tableau_tri[${x},${y},0]+=" ${i}"
                    done
                done
                Tableau_tri[${x},${y},0]=`echo ${Tableau_tri[${x},${y},0]}`
                Tableau_tri[${x},${y},0]=${Tableau_tri[${x},${y},0]// /|}
            fi
            Tableau_tri[${x},${y},1]="`echo "${headwords}" | grep -oE '~[0-9]+' | grep -oE '[0-9]+'`"
            Tableau_tri[${x},${y},1]=`echo ${Tableau_tri[${x},${y},1]}`
            Tableau_tri[${x},${y},1]=${Tableau_tri[${x},${y},1]// /|}
            if echo "${headwords}" | grep -oEq '/[0-9]+';then
                Tableau_tri[${x},${y},2]=`echo "${headwords}" | grep -oE '/[0-9]+' | grep -oE '[0-9]+' | tail -n 1`
            else
                Tableau_tri[${x},${y},2]=0
            fi
            # défaut sa valeur à 0
            Tableau_tri[${x},${y},3]=0
            Tableau_tri[${x},${y},4]=0
        done
        #ligne de commande de comportement
        Tableau_tri[${x},6,0]="${Line}"
        x=`expr ${x} + 1`
    done
    total_length=${x}

    #Comparez l'heure actuelle avec l'heure de la commande de réglage
    while [ 1 ]
    do
        varDate[0]=`date "+%S" | sed 's/0*\([0-9]\)/\1/'`
        #Étant donné que l'exigence est de 15 secondes, actualisez-la en tant que 15 secondes

        varDate[0]=`expr ${varDate[0]} / 15`
        varDate[1]=`date "+%M" | sed 's/0*\([0-9]\)/\1/'`
        varDate[2]=`date "+%H" | sed 's/0*\([0-9]\)/\1/'`
        varDate[3]=`date "+%d" | sed 's/0*\([0-9]\)/\1/'`
        varDate[4]=`date "+%m" | sed 's/0*\([0-9]\)/\1/'`
        varDate[5]=`date "+%w"`
        #Commencez à comparer
        for ((x=0; x<total_length; x++))
        do
        #Définir des variables d'indicateur
        #De bas en haut, comparez si la valeur correspondante est la même que le paramètre de temps actuel
            boolX=0
            for ((y=0; y<6; y++))
            do
                if [ ${boolX} = 0 ];then

                    if [ ${Tableau_tri[${x},${y},0]} != '*' ]

                    then
                        if  ${varDate[${y}]} =~ ${Tableau_tri[${x},${y},0]}
                        
                        then

                            boolX=1
                        fi
                    fi
                fi
                if  ${boolX} = 0 
                then
                #La troisième place du tableau tridimensionnel stocke le temps non autorisé
                #Si ce n'est pas dans le délai non autorisé, exécutez la commande
                    if  ${#Tableau_tri[${x},${y},1]} != 0 
                    then
                        if  ${varDate[${y}]} =~ ${Tableau_tri[${x},${y},1]} 

                        then
                            boolX=1
                        fi
                    fi
                fi
                if ${boolX} = 0 

                then
                    if  ${Tableau_tri[${x},${y},2]} != 0 

                    then
                        if${varDate[${y}]} != ${Tableau_tri[${x},${y},4]} 

                        then
                            Tableau_tri[${x},${y},3]=`expr Tableau_tri[${x},${y},3] + 1`
                            ((Tableau_tri[${x},${y},3]%=Tableau_tri[${x},${y},2]))
                            Tableau_tri[${x},${y},4]=${varDate[${y}]}
                        fi
                        if Tableau_tri[${x},${y},3] != 0 

                        then
                            boolX=1
                        fi
                    fi
                fi
            done
            if  ${boolX} = 0 
            
            then
            #Ecrire la commande exécutée dans le fichier  /var/log/tacheron
                echo " ${Tableau_tri[${x},6,0]} " >> /var/log/tacheron
            fi
        done
        sleep 15
    done
else
    echo "Error" >> /var/log/tacheron
fi
