#!/bin/bash
tanggal=$(date "+%d_%b_%Y"); jam=$(date "+%T")  #buat detail kapan pemeriksaan dilakukan
tanggal_format_mbsc=$(date "+%Y%m%d")
tanggal_log=$(date +%Y-%m-%d)
cm_dir=/export/home/sysm/ftproot/TimerTask/CFGMML
folder_log=/home/sse/.hansip/log/2g_cm_autobak_check
folder_database=/home/sse/.hansip/script/2G_autobak_cm_database
folder_temporary=/home/sse/.hansip/script/cfgmml

#Function untuk ambil data CFGMML di server OSS
ambil_data_cm() {
echo "Lagi berkunjung ke OSS $1"
(lftp -c "set sftp:connect-program 'ssh -o StrictHostKeyChecking=no'; open -u $3,$4 sftp://$2; cls -l --sort=date $5; quit") >> "$1_raw.txt"
}

#proses ambil data CFGMML di OSS
(
mkdir -p "$folder_temporary"
cd "$folder_temporary" || return

# Struktur Parameter =>  OSS    IP    username    password        folder_CFGMML
#                        $1     $2      $3          $4                 $5

ambil_data_cm "Bali" 10.212.82.4 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "Central_Java" 10.212.86.5 ftpuser Changeme_123 $cm_dir
ambil_data_cm "Central_Sumatera" 10.212.83.57 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "East_Java" 10.212.85.5 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "Jabodetabek_18" 10.168.194.5 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "Jabodetabek_23" 10.168.194.48 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "Jabodetabek_26" 10.168.194.100 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "North_Sumatera" 10.212.83.83 ftptest T3lk0ms3l#2 $cm_dir #diprotect TLS, ngga bisa masuk via clear-text ftp
ambil_data_cm "Nusa_Tenggara" 10.212.82.32 ftptest T3lk0ms3l#2 $cm_dir
ambil_data_cm "South_Sumatera" 10.212.83.5 ftpuser Changeme_123 $cm_dir
ambil_data_cm "West_Java" 10.168.197.5 ftptest T3lk0ms3l#2 $cm_dir
)

## Pengelompokan sesuai MBSC/RNC per oss 
( cd "$folder_temporary" || return

kelompok_oss()
{
	echo "sedang mengelompokan OSS $1"
	grep "MBSC" "$1_raw.txt" | grep "$tanggal_format_mbsc" >> "$1.txt"
}

kelompok_oss "Jabodetabek_23"
kelompok_oss "Nusa_Tenggara"
kelompok_oss "North_Sumatera"
kelompok_oss "East_Java"
kelompok_oss "South_Sumatera"
kelompok_oss "Jabodetabek_26"
kelompok_oss "Central_Java"
kelompok_oss "Jabodetabek_18"
kelompok_oss "Bali"
kelompok_oss "West_Java"
kelompok_oss "Central_Sumatera"
kelompok_oss "South_Sumatera"
kelompok_oss "North_Sumatera"
)

## Mencocokan antara database dan CFGMML, bila ada yang kurang, lempar ke file csv untuk dilaporkan
(
cd $folder_database || return
(echo "Diperiksa Pada ,$tanggal" ; echo "Jam ,$jam" ;echo " "; echo "OSS,MBSC,$tanggal,Time_Stamp OSS" ) >> "file_check.csv"
for oss in $(cat list_database.txt) ; do
echo "Sedang mengecek OSS $oss"
	for MBSC in $(cat $oss) ; do
	echo "Lagi check $MBSC"
	echo "$oss" | sed 's/.txt//g' | sed 's/_non_66//g' |tr "\n" "," >> "file_check.csv"       #Kolom OSS
	echo "$MBSC" | tr '\n' ',' >> "file_check.csv"     #Kolom BSC/RNC
	#(echo "$oss" | grep -q "non_66";  if [ $? -eq 1 ] ; then echo "Yes" | tr '\n' ',' ; else echo "No" | tr '\n' ',' ; fi ) >> "file_check.csv" # Kolom Part 66 City
	#clear_list=$(echo "$oss" | sed 's/_non_66//g') #pengaman untuk proses membanding database dengan file non 66 city
	#clear_item=$(echo "$MBSC" | sed 's/\#//g') #pengaman untuk MBSC yang dikasih tanda "#" karna statusnya lagi dc sementara
	grep "$MBSC"_ "$folder_temporary/$oss"  ; if [ $? -eq 0 ] ; then echo "ada" | tr '\n' ',' >> "file_check.csv" ; else echo "missing" | tr '\n' ',' >> "file_check.csv"; fi #Kolom Status
	(grep -oP "(?<="$MBSC"_)[^ ][0-9]{1,8}"  "$folder_temporary/$oss" || if [ $? -eq 1 ] ; then echo "-"  ; else return; fi) | head -1 >> "file_check.csv" #Kolom Time_stamp
	done
done
echo "Mencocokan file selesai, saatnya save file ke folder yang diinginkan"
mv "file_check.csv" "$folder_log"/"2g_cm_check_huawei_autobakdata_$tanggal_log.csv"
)

##aktifitas selesai, saatnya simpen file penting dan bersih bersih
#simpen_file=$(zenity --file-selection --directory --title="Pilih tempat simpan file" --filename=/home/iqbal/Kerja/imobi/task/Operation/log/)
#zip -r file_oss_check.zip cfgmml/ file_check.txt
#mv file_oss_check_$tanggal.csv file_oss_check.zip "$simpen_file" #pindahin file csv ke folder pilihan pengguna
rm --recursive "$folder_temporary"  #bersihin folder tempat ekstrak file, dll
