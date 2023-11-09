#!/bin/bash

tanggal=$(date +%Y-%m-%d)
log_folder=/home/sse/.hansip/log/alltech_cm_nbi_check_huawei/

oss_huawei="oss_Central_Sumatera
oss_North_Sumatera
oss_South_Sumatera
oss_Jabodetabek_18
oss_Jabodetabek_23
oss_Jabodetabek_26
oss_West_Java"


#array untuk set batas bawah jumlah cm file
#kalau dibawah batas, muncul alarm
declare -A hansip_alarm_treshold
hansip_alarm_treshold['oss_Central_Sumatera']=4
hansip_alarm_treshold['oss_North_Sumatera']=10
hansip_alarm_treshold['oss_South_Sumatera']=35
hansip_alarm_treshold['oss_Jabodetabek_18']=20
hansip_alarm_treshold['oss_Jabodetabek_23']=25
hansip_alarm_treshold['oss_Jabodetabek_26']=25
hansip_alarm_treshold['oss_West_Java']=32

#array untuk simpan cm oss yang jumlah file nya dibawah treshold
declare -A hansip_alarm_list=()

(
for oss in $oss_huawei; do
count_cm_file=$(find /opt/nfs-data/shares/raw_data/huawei/sd/5g/"$oss"/ -type f -mtime -1 | wc -l)
echo "$oss : $count_cm_file"

if [ "$count_cm_file" -lt "${hansip_alarm_treshold[$oss]}" ];
        then
        hansip_alarm_list["$oss"]="$count_cm_file"

fi
done

#kalau ngga ada cm oss yang dibawah treshold
if [ "${#hansip_alarm_list[@]}" -eq 0 ] ;
        then
        echo 'All Huawei CM NBI XML is up to date'

#kalau ada cm oss yang dibawah treshold
else
        echo '[HANSIP ALARM] There is Huawei CM NBI XML that Outdated/Below Threshold'
        for alarm in "${!hansip_alarm_list[@]}"; do printf "%s : %s\n" "$alarm" "${hansip_alarm_list[$alarm]}" ; done
fi
)> "$log_folder/alltech_cm_nbi_check_huawei_$tanggal.log"

