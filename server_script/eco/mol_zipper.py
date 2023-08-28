#!/usr/bin/env python3
import sys
import shutil
from datetime import datetime

#buat variable tanggal sama folder yang mau di zip
#tanggal = datetime.now().strftime("%Y-%m-%d")
tanggal = sys.argv[1] #ambil tanggal dari argumen yang di pass sama script mol_collector.sh
folder_to_be_zipped = "/home/sse/.auto_zip/MOL_" + tanggal + "/"
output_zip_file = "/home/sse/MOL_" + tanggal


#zip folder MOL nya
shutil.make_archive(output_zip_file,"zip",folder_to_be_zipped)

