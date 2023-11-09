#!/bin/bash

tanggal=$(date +%Y-%m-%d)
log_folder=/home/sse/.hansip/log/alltech_cm_check_ericsson

list_cm_eri=$(
for enm in 08 09 10 11 ; do ls -lh --time-style="+%Y-%m-%d %H:%M:%S" /opt/nfs-data/shares/raw_data/enm/oss_Ran$enm/sd/
printf '\n'
done
)

(
echo "$list_cm_eri"

find_outdated_eri_cm=$(echo "$list_cm_eri" | grep -i --invert-match 'total' |grep --invert-match "$tanggal")
#find_outdated_eri_cm=$(echo "$list_cm_eri" | grep  "$tanggal") #just for test case

if [ -n "$(echo "$find_outdated_eri_cm" | head -n 1 | tr " " ",")" ]; #head and tr resolve "too many argument" issue
        then
        echo " "
        echo '[HANSIP ALARM] There is ERI CM that Outdated, here is the list : ' | tr "\n" " "
        echo -n $(echo "$find_outdated_eri_cm" | grep -io "Ran..") | tr "\n" " "

else
        echo " "
        echo 'All ERI CM is up to date'
fi

)> "$log_folder/alltech_cm_check_ericsson_$tanggal.log"
