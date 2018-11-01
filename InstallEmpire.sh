#!/bin/bash

apt update
apt install python python-pip -y
pip install --upgrade pip
hash -d pip

apt remove python-urllib3
pip install 'urllib3<1.23,>=1.21.1'

git clone https://github.com/EmpireProject/Empire
cd Empire/setup
export STAGING_KEY="RANDOM"
./install.sh
