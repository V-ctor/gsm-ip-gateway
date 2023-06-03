#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
BOT_ID=$(grep -Po '(?<=BOT_ID=).*' "$tokens_file")
CHAT_ID=$(grep -Po '(?<=CHAT_ID=).*' "$tokens_file")
EMAIL_TO=$(grep -Po '(?<=EMAIL_TO=).*' "$tokens_file")

# Get the paths to the two latest voicemail files with .wav extension
wav_file=$1
date_time=$2
caller_num=$3

# Echo the paths of the two latest voicemail files
echo "$wav_file"
opus_file="${wav_file%.wav}.opus"
echo "$opus_file"
opusenc "$wav_file" "$opus_file"
description="Call from $caller_num at $date_time"

tg_result=$(curl -X POST -H "Content-Type:multipart/form-data"\
  -F document=@"$opus_file" "https://api.telegram.org/$BOT_ID/sendDocument?chat_id=$CHAT_ID"\
  -F caption="$description")

tg_status=$(echo "$tg_result" | grep -oP '"ok"\s*:\s*\K[^,}]+')

email_result=$(echo "$description" | /usr/bin/mutt -F /etc/Muttrc -s "Voice record"  "$EMAIL_TO" -a "$opus_file")
echo "$email_result"

if [[ "$tg_status" = "true" || $? -eq 0 ]]; then
    all_last_records_files="${wav_file%.wav}.*"
    echo $all_last_records_files | xargs rm -v
fi