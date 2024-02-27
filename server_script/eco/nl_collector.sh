#!/bin/bash

#variable tanggal hari ini, format = YYYY-MM-DD
#tanggal="2023-08-24"
tanggal=$(date +%Y-%m-%d)

output_path=/home/sse/NL_PROD_Summary
output_file=$output_path/NL_PROD_$tanggal.txt

mkdir -p $output_path



# mkdir nama folder nya NL_tanggal
folder_collector="/home/sse/.auto_zip/NL_$tanggal"
temp_output=$folder_collector/temporary.txt



mkdir $folder_collector

# find dan copy MO log sesuai tanggal hari ini ke folder yang tadi dibuat
find /opt/shares/tsel_prod_vio/services_logs/jobs/ -name "*${tanggal}_??_??_??.netConfLoadingJob.*" -exec cp "{}" $folder_collector \;

# open gzip content
(
cd $folder_collector/ || return
gzip -d -- *.gz
)

# grep useful info from NL Load log
(
cd $folder_collector/ || return
for item in $(ls -- *[.log]) ; do
        (
        # Source
        head -n 500 "$item" | grep -oP "(?<=Path /opt/raw_data/)[^ ]*"  | tr '\n' ','

        # Set a barier to grep # cell loaded
        baris_awal=$(grep -n "Executing step: \[netLoadingJob_activateNetworkSnapshotStep\]" "$item" | cut -d: -f 1 | head -n 1); baris_akhir="$(($baris_awal + 50))"

        # 5G Cell Loaded
        sed ''"$baris_awal"','"$baris_akhir"'!d' "$item" | egrep -o "The network has [0-9]{1,7} active NR sectors" | egrep -o "[0-9]{1,7}" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "no data" | tr '\n' ',' ; else return; fi


        # 4G Cell Loaded
        sed ''"$baris_awal"','"$baris_akhir"'!d' "$item" |egrep -o "The network has [0-9]{1,7} active LTE sectors" | egrep -o "[0-9]{1,7}" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "no data" | tr '\n' ',' ; else return; fi


        # 2G Cell Loaded
        sed ''"$baris_awal"','"$baris_akhir"'!d' "$item" |egrep -o "The network has [0-9]{1,7} active GSM sectors" | egrep -o "[0-9]{1,7}" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "no data" | tr '\n' ',' ; else return; fi


        # Missing Sector
        grep -oP "(?<=Failed to find physical data for )[^ ]*" "$item" | tr '\n' ','

        # Network Load Status
        tail -n 100  "$item" | grep -oP "(?<=completed with the following status: )[^ ]*" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "running" | tr '\n' ',' ; else return; fi

        # Network Load Finish Time stamp
         tail -n 100  "$item" | grep "completed with the following status:" | grep -oP "(?<="$tanggal"T)[^\,]*" || if [ $? -eq 1 ] ; then echo "running" ; else return; fi


) >> $temp_output

done

)

# sort by vendor name and put it on output folder
(
echo "Source,5G Sector,4G Sector,2G Sector,Total Missing Sector,NL Load Status,Time Stamp"
grep enm $temp_output | sort ; echo " "
grep huawei $temp_output | sort ; echo " "
) > $output_file



#zip folder collector pake python script
#python3 /home/sse/.auto_zip/script/nl_zipper.py $tanggal

#bersihin folder collector biat /home ngga penuh
rm -rf $folder_collector

#sementara segini dulu, nanti nambah lagii function nya

### PR

# rename setiap log pake "tech_region" misal "4g_North_Sumatera" jadi enak kalau mau troubleshot

# remove duplicate log, misal ada log hasil re run kan duplicate tuh

