#!/bin/bash

#variable tanggal hari ini, format = YYYY-MM-DD
tanggal=$(date +%Y-%m-%d)
#tanggal="2023-08-24"

output_path=/home/sse/MOL_PROD_Summary
output_file=$output_path/MOL_PROD_$tanggal.txt


mkdir -p $output_path



# mkdir nama folder nya MOL_tanggal
folder_collector="/home/sse/.auto_zip/MOL_$tanggal"
temp_output=$folder_collector/temporary.txt

mkdir $folder_collector

# find dan copy MO log sesuai tanggal hari ini ke folder yang tadi dibuat
find /opt/shares/tsel_prod_vio/services_logs/jobs/ -name "*${tanggal}_??_??_??.moLoadingJob.*" -exec cp "{}" $folder_collector \;

# open gzip content
(
cd $folder_collector/ || return
gzip -d -- *.gz
)

# grep useful info from MO Load log
(
cd $folder_collector/ || return
for item in $(ls -- *[.log]) ; do
        (
        # Source	
	head -n 500 "$item" | grep -oP "(?<=source: /opt/raw_data/)[^ ]*"  | tr '\n' ','
        # Number of item/MO stored to vertica dB
	tail -n 100 "$item" | grep -oP "(?<=Finishing loading network model to DB.Number of records loaded )[^ ]*" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "fail" | tr '\n' ',' ; else return ; fi 
	# MO Load Status 
	tail -n 100  "$item" | grep -oP "(?<=completed with the following status: )[^ ]*" | tr '\n' ',' || if [ $? -eq 1 ] ; then echo "running" | tr '\n' ',' ; else return; fi
	# MO Load Finish Time stamp
         tail -n 100  "$item" | grep "completed with the following status:" | grep -oP "(?<="$tanggal"T)[^\,]*" || if [ $? -eq 1 ] ; then echo "running" ; else return; fi

	) >> $temp_output

done
)


# sort by vendor name and put it on output folder
(
echo "Source,Item Stored to dB,MO Load Status,Time Stamp"
grep enm $temp_output | sort ; echo " "
grep huawei $temp_output | sort ; echo " "
) > $output_file







#zip folder collector pake python script
#python3 /home/sse/.auto_zip/script/mol_zipper.py $tanggal

#bersihin folder collector biat /home ngga penuh
rm -rf $folder_collector

#sementara segini dulu, nanti nambah lagii function nya

### PR

# rename setiap log pake "tech_region" misal "4g_North_Sumatera" jadi enak kalau mau troubleshot

# remove duplicate log, misal ada log hasil re run kan duplicate tuh

