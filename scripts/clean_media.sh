#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <media_directory> <path_to_chat.txt>"
    exit 0
fi

MEDIA_DIR=$1
CHAT_TXT_PATH=$2

# find "$MEDIA_DIR" -mindepth 2 -type f '!' -name '.nomedia' -exec mv -t "$MEDIA_DIR" -i '{}' +
# find "$MEDIA_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf '{}' \;
for f in *; do
    if grep "$f" "$CHAT_TXT_PATH" > /dev/null; then
        echo "+$f"
    else
        echo "-$f"
        rm "$f"
    fi
done
