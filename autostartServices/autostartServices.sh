#!/bin/bash
# autostartServices.sh
# autostarts necessary Rx30 services (specifically designed to handle regular automatic reboots)
# usage outside of a reboot scenario (all services down) is untested, do not use on production servers
# Travis Cochran 2023, modified from /usr/rx30/usbbak

# I don't know why the order matters, but it does. Basic processes first, then Virtual RPh, then Lifeline

[ -d $HOME/htp/logs ] || mkdir $HOME/htp/logs
LOGFILE="$HOME/htp/logs/`date +%F`-`date +%H%M`_autostartServices.sh.log"
PROCLIST="$HOME/htp/autostartServicesServiceList.conf"
BFILEDIR="$HOMEDIR/.rx30backup"

YOURTERM=$TERM
export TERM=scoansi

# starts basic services
for i in `cat $PROCLIST`
do
    pgrep -u $USER $i
    if [ $? -eq 0 ]
    then
        echo "Did not start $i - already running" >>$LOGFILE
    else 
        $HOME/$i &
        sleep 1
        pgrep -u $USER $i
        if [ $? -eq 0 ]
        then
            echo "$i - start ok" >>$LOGFILE
        else
            echo "$i - start failed" >>$LOGFILE
        fi
    fi
done

sleep 10

# starts Virtual RPh
$HOME/rx30.exe bg &
if [ -f $HOME/rx30arf.cnf ] &&  grep VirtRPH $BFILEDIR/usbbackup 
then
    DISPLAY=:0 $HOME/rx30.exe autostart &
    sleep 2
    ps -ef | grep -v grep | grep -w "rx30.exe autostart"
    VPERR=$?
    sleep 1
    if [ $VPERR -eq 0 ] 
        then
            echo "Virtual Pharmacist - start ok" >>$LOGFILE
        else
            echo "Virtual Pharmacist - start failed" >>$LOGFILE
    fi
fi

# starts Lifeline
pgrep -u $USER lifeline
if [ $? -eq 0 ]
then
    echo "Lifeline already running" >>$LOGFILE
else 
    $HOME/lifeline &
    sleep 3
    pgrep -u $USER lifeline
    if [ $? -eq 0 ]
    then
        echo "lifeline - start ok" >>$LOGFILE
    else
        echo "lifeline - start failed" >>$LOGFILE
    fi
fi
TERM=$YOURTERM