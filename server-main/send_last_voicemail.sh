#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
BOT_ID=$(grep -Po '(?<=BOT_ID=).*' "$tokens_file")
CHAT_ID=$(grep -Po '(?<=CHAT_ID=).*' "$tokens_file")
EMAIL_TO=$(grep -Po '(?<=EMAIL_TO=).*' "$tokens_file")

voicemail_dir="/var/spool/asterisk/voicemail/voice-mail/common/INBOX"  # Replace with the desired voicemail directory and mailbox

src_full_name=$1
source=$2 #[email|monitor]
wav_file=$src_full_name.wav
if [[ "$source" = "email" ]]; then  #voice mail keeps all meta data in msgXXX.txt
  txt_file=$src_full_name.txt
  origtime=$(cat "$txt_file" | grep -oP '(?<=origtime=).*')
  date_time=$(date -d "@$origtime" +'%Y%m%d-%H%M%S')
  exten=$(cat "$txt_file" | grep -oP '(?<=exten=).*')
  caption_postfix="(voice mail)"
else    # but mix monitor does not
  date_time=$3
  exten=$4
  caption_postfix="(monitor record)"
fi
opus_file=${src_full_name%/*}/$date_time-$exten.opus

duration=$(soxi -D "$wav_file")

# Compare the duration with 1 second
if (( $(awk -v dur="$duration" 'BEGIN {print (dur <= 1)}') )); then
    echo "WAV file duration is less than or equal to 1 second."
    all_last_records_files="$src_full_name.* $opus_file"
    echo $all_last_records_files | xargs rm -v  #it's important to avoid quotes for $all_last_records_files in spite of warning
    exit 0
fi

caption="Voice record $caption_postfix"
email_caption="$caption from: ${exten}"
email_description="From: ${exten}
Date: ${date_time}
Duration: ${duration}"
tg_description="$caption
$email_description"

opusenc "$wav_file" "$opus_file"
#description="Call from $caller_num at $date_time"

result=$(curl -X POST -H "Content-Type:multipart/form-data"\
  -F document=@"$opus_file" "https://api.telegram.org/$BOT_ID/sendDocument?chat_id=$CHAT_ID"\
  -F caption="$(echo "$tg_description" | sed 's/;//g')")

tg_status=$(echo "$result" | grep -oP '"ok"\s*:\s*\K[^,}]+')

email_result=$(echo "$email_description" | /usr/bin/mutt -F /etc/Muttrc -s "$email_caption"  "$EMAIL_TO" -a "$opus_file")
echo "$email_result"

if [[ "$tg_status" = "true" || $? -eq 0 ]]; then
    all_last_records_files="$src_full_name.* $opus_file"
    echo $all_last_records_files | xargs rm -v  #it's important to avoid quotes for $all_last_records_files in spite of warning
fi