#!/usr/bin/env python
import exifread
import datetime
import hashlib
import os
import shutil
import subprocess

# config no trailing slashes please
source_path = '/media/drivemount/user/files/PhotosToSort'
destin_path = '/media/drivemount/user/files/Photos'

# check if destination path is existing create if not
if not os.path.exists(destin_path):
    os.makedirs(destin_path)

# file hash function
def hash_file(filename):

   # make a hash object
   h = hashlib.sha1()

   # open file for reading in binary mode
   with open(filename,'rb') as file:

       # loop till the end of the file
       chunk = 0
       while chunk != b'':
           # read only 1024 bytes at a time
           chunk = file.read(1024)
           h.update(chunk)

   # return the hex representation of digest
   return h.hexdigest()

# picture date taken function
def date_taken_info(filename):
    # Read file
    open_file = open(filename, 'rb')

    # Return Exif tags
    tags = exifread.process_file(open_file, stop_tag='Image DateTime')

    try:
        # Grab date taken
        datetaken_string = tags['Image DateTime']
        datetaken_object = datetime.datetime.strptime(datetaken_string.values, '%Y:%m:%d %H:%M:%S')

        # Date
        day   = str(datetaken_object.day).zfill(2)
        month = str(datetaken_object.month).zfill(2)
        year  = str(datetaken_object.year)
        # Time
        second = str(datetaken_object.second).zfill(2)
        minute = str(datetaken_object.minute).zfill(2)
        hour   = str(datetaken_object.hour).zfill(2)

        # New Filename
        output = [day,month,year,day + month + year + '-' + hour + minute + second]
        return output

    except:
        return None

# get all picture files from directory and process
for file in os.listdir(source_path):
    if file.endswith('.jpg'):      
        filename = source_path + os.sep + file
        dateinfo = date_taken_info(filename)
        try:
            out_filepath = destin_path + os.sep + dateinfo[2] + os.sep + dateinfo[1]
            out_filename = out_filepath + os.sep + dateinfo[3] + '.jpg'

            # check if destination path is existing create if not
            if not os.path.exists(out_filepath):
                os.makedirs(out_filepath)

            # copy the picture to the organised structure
            shutil.copy2(filename,out_filename)

            # verify if file is the same and display output
            if hash_file(filename) == hash_file(out_filename):
                print 'File copied with success to ' + out_filename
                os.remove(filename)
            else:
                print 'File failed to copy :( ' + filename
            
        except:
            print 'File has no exif data skipped ' + filename


# initate a scan
subprocess.Popen("php /var/www/html/nextcloud/console.php files:scan --all", shell=True, stdout=subprocess.PIPE)
