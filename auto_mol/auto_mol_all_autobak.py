#! python
import os
import tkinter as tk
import shutil
import gzip
import re
import glob
from tkinter import filedialog #buat pilih file MOL
from pathlib import Path
from shutil import copy, rmtree

## Kumpulan variabel
folder_proses = "MOL_All_PROD"


## pilih file parent MOL dan di copy in ke sini
os.mkdir(folder_proses)
root = tk.Tk()
root.withdraw()
pilih_file_parent = filedialog.askopenfilename()
nama_file_parent = Path(pilih_file_parent).stem + ".zip"
copy (pilih_file_parent, folder_proses + "/" + nama_file_parent)

## unzip file parent 
shutil.unpack_archive(folder_proses + "/" + nama_file_parent, folder_proses)
os.remove(folder_proses + "/" + nama_file_parent)

## Mengambil Time stamp dari file MOL yang di proses
list_file = os.listdir(folder_proses)
time_stamp = "".join(re.findall(r'(?<=optserver.)[^_]*',list_file[0]))

## decompress file gzip di folder MOL
for file_gzip in glob.glob(folder_proses + "/*.gz"):
	with gzip.open(file_gzip , 'rb') as f_in:
		with open(folder_proses + "/" + Path(file_gzip).stem , 'wb') as f_out:
			shutil.copyfileobj(f_in, f_out)
	os.remove(file_gzip)

## baca file log dan mencari informasi yang dibutuhkan
list_data_Ericsson_MOL = []
list_data_4G_MOL = []
list_data_3G_MOL = []
list_data_2G_MOL = []
list_data_sisa_MOL = []
for daftar_file in os.listdir(folder_proses):
	
	print ("Sedang memproses : " + daftar_file)
	
	for baris in open (folder_proses + "/" +daftar_file, "r"):
		nama_oss = re.findall(r'(?<=source: /opt/raw_data/)[^ \n ]*',baris)
		jumlah_file_terproses = re.findall(r'(?<=Finishing loading network model to DB.Number of records loaded )[^\n ]*',baris)
		
		
		if len(nama_oss) > 0 :
			simpan_nama_oss = ("".join(nama_oss)) #nama oss di rubah ke string dulu, baru di simpen ke variabl
			
		elif len (jumlah_file_terproses) > 0 :

			if "Ran" in simpan_nama_oss:
				list_data_Ericsson_MOL.append(simpan_nama_oss +"%" + "".join(jumlah_file_terproses)) #% = buat pembatas

			elif "4g" in simpan_nama_oss:
				list_data_4G_MOL.append(simpan_nama_oss +"%" + "".join(jumlah_file_terproses)) #% = buat pembatas
			
			elif "3g" in simpan_nama_oss:
				list_data_3G_MOL.append(simpan_nama_oss +"%" + "".join(jumlah_file_terproses)) #% = buat pembatas

			elif "2g" in simpan_nama_oss:
				list_data_2G_MOL.append(simpan_nama_oss +"%" + "".join(jumlah_file_terproses)) #% = buat pembatas
			
			#kalau ada MOL diluar 4G 3G 2G Huawei dan ERI
			else :
				list_data_sisa_MOL.append(simpan_nama_oss +"%" + "".join(jumlah_file_terproses)) #% = buat pembatas
			
		
		
		
	open (folder_proses + "/" +daftar_file, "r").close()

## urutkan sesuai alfabet 
list_data_Ericsson_MOL.sort()
list_data_4G_MOL.sort()
list_data_3G_MOL.sort()
list_data_2G_MOL.sort()
list_data_sisa_MOL.sort()

## write ke csv file
file_output = open(folder_proses + "_" + time_stamp + ".csv","a")
#file_output = open(folder_proses + "_"  + ".csv","a")
file_output.write("Nama OSS,Jumlah File diproses\n")

for item in list_data_Ericsson_MOL :
	file_output.write(item.replace("%", ",") + "\n")

file_output.write("\n") #new line untuk misahin antara bagian

for item in list_data_4G_MOL :
	file_output.write(item.replace("%", ",") + "\n")

file_output.write("\n") #new line untuk misahin antara bagian

for item in list_data_3G_MOL :
	file_output.write(item.replace("%", ",") + "\n")

file_output.write("\n") #new line untuk misahin antara bagian

for item in list_data_2G_MOL :
	file_output.write(item.replace("%", ",") + "\n")

file_output.write("\n") #new line untuk misahin antara bagian

for item in list_data_sisa_MOL :
	file_output.write(item.replace("%", ",") + "\n")

file_output.write("\n") #new line untuk misahin antara bagian

file_output.close()
shutil.rmtree(folder_proses)