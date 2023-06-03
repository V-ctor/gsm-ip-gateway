#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
BOT_ID=$(grep -Po '(?<=BOT_ID=).*' "$tokens_file")
CHAT_ID=$(grep -Po '(?<=CHAT_ID=).*' "$tokens_file")
EMAIL_TO=$(grep -Po '(?<=EMAIL_TO=).*' "$tokens_file")

voicemail_dir="/var/spool/asterisk/voicemail/voice-mail/common/INBOX"  # Replace with the desired voicemail directory and mailbox

# Get the paths to the two latest voicemail files with .wav extension
wav_file=$(ls -t "$voicemail_dir"/*.wav 2>/dev/null | head -n1)

# Get the paths to the two latest voicemail files with .txt extension
txt_file=$(ls -t "$voicemail_dir"/*.txt 2>/dev/null | head -n1)

# Echo the paths of the two latest voicemail files
echo "$wav_file"
echo "$txt_file"
opus_file="${wav_file%.wav}.opus"
opusenc "$wav_file" "$opus_file"
#description="Call from $caller_num at $date_time"

result=$(curl -X POST -H "Content-Type:multipart/form-data"\
  -F document=@"$opus_file" "https://api.telegram.org/$BOT_ID/sendDocument?chat_id=$CHAT_ID"\
  -F caption="$(cat "$txt_file" | sed 's/;//g')")

tg_status=$(echo "$result" | grep -oP '"ok"\s*:\s*\K[^,}]+')

email_result=$(cat "$txt_file" | /usr/bin/mutt -F /etc/Muttrc -s "Voice record"  "$EMAIL_TO" -a "$opus_file")
echo "$email_result"

if [[ "$tg_status" = "true" || $? -eq 0 ]]; then
    all_last_records_files="${wav_file%.wav}.*"
    echo $all_last_records_files | xargs rm -v  #it's important to avoid quotes for $all_last_records_files in spite of warning
fi