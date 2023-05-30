#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
BOT_ID=$(grep -Po '(?<=BOT_ID=).*' "$tokens_file")
CHAT_ID=$(grep -Po '(?<=CHAT_ID=).*' "$tokens_file")

# Get the paths to the two latest voicemail files with .wav extension
wav_file=$1
date_time=$2
caller_num=$3

# Echo the paths of the two latest voicemail files
echo "$wav_file"
opus_file="${wav_file%.wav}.opus"
opusenc "$wav_file" "$opus_file"

result=$(curl -X POST -H "Content-Type:multipart/form-data"\
  -F document=@"$opus_file" "https://api.telegram.org/$BOT_ID/sendDocument?chat_id=$CHAT_ID"\
  -F caption="Call from $caller_num at $date_time")

tg_status=$(echo "$result" | grep -oP '"ok"\s*:\s*\K[^,}]+')

if [ "$tg_status" = "true" ]; then
    all_last_records_files="${wav_file%.wav}.*"
    echo $all_last_records_files | xargs rm -v
fi