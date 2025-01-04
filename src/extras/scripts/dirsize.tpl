#!/bin/bash
# @file dirsize.sh
# @project MediaEase
# @version 1.0.0
# @description A simple script to calculate the total size of files in the current directory
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

TotalBytes=0
for Bytes in *; do
    if [ -f "$Bytes" ]; then
        Size=$(stat -c %s "$Bytes")
        TotalBytes=$((TotalBytes + Size))
    fi
done
if [ "$TotalBytes" -lt 1024 ]; then
    TotalSize=$(echo -e "scale=1 \n$TotalBytes \nquit$(tput sgr0)" | bc)
    suffix="b"
elif [ "$TotalBytes" -lt 1048576 ]; then
    TotalSize=$(echo -e "scale=1 \n$TotalBytes/1024 \nquit$(tput sgr0)" | bc)
    suffix="kb"
elif [ "$TotalBytes" -lt 1073741824 ]; then
    TotalSize=$(echo -e "scale=1 \n$TotalBytes/1048576 \nquit$(tput sgr0)" | bc)
    suffix="Mb"
else
    TotalSize=$(echo -e "scale=1 \n$TotalBytes/1073741824 \nquit$(tput sgr0)" | bc)
    suffix="Gb"
fi
echo -en "${TotalSize}${suffix}"
