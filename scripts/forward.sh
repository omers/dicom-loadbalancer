# storescp \
#   --output-directory /tmp \
#   --exec-on-reception /forward.sh 11211



#!/bin/bash
DICOM_FILE="$1"

# Send it to the destination PACS using storescu
storescu -b 127.0.0.1:3030 -c ios@127.0.0.1:30301 "$DICOM_FILE"


rm "$DICOM_FILE"
