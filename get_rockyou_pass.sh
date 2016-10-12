#!/bin/bash

echo "tested and working on Kali"

grep -x '^[A-Z]\{1\}[a-z]\{7\}[0-9]\{1\}[!"£$%^&*()]' /usr/share/wordlists/rockyou.txt | shuf -n 1
