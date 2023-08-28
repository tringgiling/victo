#!/bin/bash

#variable tanggal hari ini, format = YYYY-MM-DD
#tanggal="2023-08-24"
tanggal=$(date +%Y-%m-%d)

# mkdir nama folder nya NL_tanggal
folder_collector="/home/sse/.auto_zip/NL_$tanggal"
mkdir $folder_collector

# find dan copy MO log sesuai tanggal hari ini ke folder yang tadi dibuat
find /opt/shares/tsel_prod_vio/services_logs/jobs/ -name "*${tanggal}_??_??_??.netConfLoadingJob.*" -exec cp "{}" $folder_collector \;

#zip folder collector pake python script
python3 /home/sse/.auto_zip/script/nl_zipper.py $tanggal

#bersihin folder collector biat /home ngga penuh
rm -rf $folder_collector

#sementara segini dulu, nanti nambah lagii function nya

### PR

# rename setiap log pake "tech_region" misal "4g_North_Sumatera" jadi enak kalau mau troubleshot

# remove duplicate log, misal ada log hasil re run kan duplicate tuh

