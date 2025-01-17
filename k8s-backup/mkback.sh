#!/bin/bash
SSH_OPTS='-q -p 12000 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
BACKUPDIR=/tank/Backups
DATE=`date "+%Y-%m-%d"`
YESTERDAY=`TZ="UTC+14" date "+%Y-%m-%d"`
# Quick snapshot of k8s volumes first
zfs snapshot tank/Volumes@${YESTERDAY} 
# Now for the non-volume stuff
for HOSTNAME in tinkerboard website piserve
    do echo 
    if [ "$HOSTNAME" = "website" ]
        then DIR=/home/cjd/Docker-Data
    elif [ "$HOSTNAME" = "tinkerboard" ]
        then DIR=/home/cjd/Docker-Data
    elif [ "$HOSTNAME" = "piserve" ]
        then DIR=/var/lib/rancher/k3s/server
    else echo No/Unknown host specified; exit;
    fi
    echo "##############################"
    echo "#### Backing up $HOSTNAME ####"
    echo "##############################"
    cd $BACKUPDIR
    zfs snapshot tank/Backups/${HOSTNAME}@${YESTERDAY}
    rsync --archive --delete-during --verbose --human-readable --partial --stats --inplace -e "ssh ${SSH_OPTS}" $EXCLUDE root@$HOSTNAME:$DIR $BACKUPDIR/${HOSTNAME}
    
    for DATE in `zfs list -t all |grep $HOSTNAME|grep "@20"|sed -e 's/^.*@\([0-9-]*\) .*$/\1/g'|sort -u|head -n -7`
        do KEEP=`date -d "$DATE" +%u`
        if [ $KEEP -ne 1 ]
            then for ZFS in `zfs list -t all|grep $DATE | cut -f1 -d' '`
            do zfs destroy -v $ZFS
            done
        fi
    done
done
