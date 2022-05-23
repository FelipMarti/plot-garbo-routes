#!/bin/bash

echo
echo "  ###########################################################"
echo "  #                                                         #"
echo "  #  The GarboDownloader: Downloading logs from all Garbos  #"
echo "  #                                                         #"
echo "  ###########################################################"
echo


# "ID NameHost IPAddrs"
# ID counting from 0 to N so we can remove it from the array when ends OK
declare -a servers=(
    "0 Garbo01 172.16.50.1"
    "1 Garbo02 172.16.50.2"
    "2 Garbo03 172.16.50.3"
    "3 Garbo04 172.16.50.4"
    "4 Garbo05 172.16.50.5"
    "5 Garbo06 172.16.50.6"
    "6 Garbo07 172.16.50.7"
    "7 Garbo08 172.16.50.8"
    "8 Garbo09 172.16.50.9"
    "9 Garbo10 172.16.50.10"
    "10 Garbo11 172.16.50.11"
    "11 Garbo12 172.16.50.12"
    "12 Garbo13 172.16.50.13"
    "13 Garbo14 172.16.50.14"
)


function get_day_to_download()
{
    # We need to get the previous day, but not weekends
    dow=`date +%u`
    if [ $dow -eq 1 ]; then
        # Monday we get data from Friday
        echo `date --date="3 days ago" +%F`
    elif [ $dow -gt 1 ] && [ $dow -lt 6 ]; then
        # Tue to Fri we get data from previous day
        echo `date --date="1 day ago" +%F`
    else
        # Weekend. Garbos are off, we don't get data.
        exit 0 
    fi
}

DATE=$(get_day_to_download)
if [ "$DATE" = "" ]; then
    echo "Weekend. Garbos are off, we don't get data."
    exit 0
fi

USER=garbo
DATA_FOLDER=~/Data/garbo-GPS
TODAYS_DATE=$DATE
SERVERS_FAIL_FILE=$DATA_FOLDER/$TODAYS_DATE/$TODAYS_DATE-servers.fail
SCRIPT_PATH=$(realpath $0)
ERROR=0

PYTHON_BIN=/usr/bin/python3 
PLOT_SCRIPT=~/Code/plot-garbo-routes/GPS-visualization-Python/main.py 
REMOTE_FOLDER_PATH=OneDrive:Projects/2021-5G/2021-5G-Brimbank-Data/Garbos-GPS

mkdir -p $DATA_FOLDER/$TODAYS_DATE

# Checking if the script has been executed today with errors
# to download only from servers that were unsuccessful.
if test -f "$SERVERS_FAIL_FILE"; then
    source $SERVERS_FAIL_FILE
fi


echo
echo -e "Downloading GPS log files for all Garbos UP: \e[1;33m$FOLDER\e[0;39m"
echo
echo -e "Waiting 5 seconds"
echo
echo
sleep 5


for server in "${servers[@]}"; do 
    read -a serverN <<< "$server"
    NUM_ID=${serverN[0]}
	HOST=${serverN[1]}
	IP=${serverN[2]}
	echo -e "\e[1;39m[$USER at $HOST ($IP)] \e[0;39m"

    if ping -c1 -W1 $IP &> /dev/null; then
        echo -e "$HOST ($IP) is \e[1;32mUP\e[0;39m, executing commands"
	    scp $USER@$IP:log/$TODAYS_DATE-garbo*-GPS.log $DATA_FOLDER/$TODAYS_DATE
        if [ $? -eq 0 ]; then
            # File downloaded, removing server from the list
            unset servers[$NUM_ID]
            echo ${servers[@]}
        else
            ERROR=1
        fi
    else
        echo -e "$HOST ($IP) is \e[1;31mDOWN \e[0;39m"
        ERROR=1
    fi

	echo "[END $USER at $HOST]"
    echo
done


HOUR=`date +%H` 
if [ $ERROR -ne 0 ] && [ $HOUR -lt 10 ]; then
    # Errors found and less than 10 am
    # Update list of servers
    set | grep ^servers= > $SERVERS_FAIL_FILE
    # Execute in 5 minutes 
    echo $SCRIPT_PATH | at now + 5 min 
else
    # Script finished with no errors 
    # or it is later than 10am 
    echo "NO Error or later than 10 am. Plotting"

    # Update list of servers
    set | grep ^servers= > $SERVERS_FAIL_FILE

    # Plotting files
    $PYTHON_BIN $PLOT_SCRIPT -f $DATA_FOLDER/$TODAYS_DATE

    # Copying to OneDrive, log files and .eps
    rclone copy $DATA_FOLDER/$TODAYS_DATE $REMOTE_FOLDER_PATH/$TODAYS_DATE 
    rclone copy $DATA_FOLDER/$TODAYS_DATE.eps $REMOTE_FOLDER_PATH/$TODAYS_DATE 

fi
