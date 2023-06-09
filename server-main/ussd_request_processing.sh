#!/bin/bash

tokens_file=/etc/asterisk/extensions_tokens.conf
BOT_ID=$(grep -Po '(?<=BOT_ID=).*' "$tokens_file")
CHAT_ID=$(grep -Po '(?<=CHAT_ID=).*' "$tokens_file")
USSD_PATTERN="\s*\*102#$"
NOT_ALLOWED_USSD_MESSAGE="String does not match allowed USSD pattern. Allowed: *102# - get balance"
NOT_ALLOWED_USSD_MESSAGE_URL=$(printf %s "$NOT_ALLOWED_USSD_MESSAGE"|jq -sRr @uri)

# File to store the offset
tmp_dir=${XDG_RUNTIME_DIR:-${TMPDIR:-${TMP:-${TEMP:-/tmp}}}}
OFFSET_FILE="$tmp_dir/tg_bot_offset.txt"
if [[ -f "$OFFSET_FILE" ]]; then
  OFFSET=$(cat "$OFFSET_FILE")
else
  OFFSET=0
fi

url="https://api.telegram.org/${BOT_ID}/getUpdates?offset=${OFFSET}"
response=$(curl -s "$url" | jq)
echo $response
if [[ $? -eq 0 ]]; then
  updates=$(echo "$response" | jq -c ".result[] | select(.message.chat.id == $CHAT_ID)")
  while IFS= read -r update; do
    update_id=$(echo "$update" | jq -r '.update_id')
    chat_id=$(echo "$update" | jq -r '.message.chat.id')
    text=$(echo "$update" | jq -r '.message.text')
    if [ -z "$text" ]; then
      exit 0
    fi
    echo "New message received: $text"
    if [[ $text =~ $USSD_PATTERN ]]; then
      echo "String matches the USSD_PATTERN!"
      asterisk -x "originate Local/$text@sms-out-simulate application Echo"
    else
      echo "$NOT_ALLOWED_USSD_MESSAGE"
      curl "https://api.telegram.org/${BOT_ID}/sendMessage?chat_id=${CHAT_ID}&text=${NOT_ALLOWED_USSD_MESSAGE_URL}"
    fi
    if [[ $update_id -ge $OFFSET ]]; then
      OFFSET=$((update_id + 1))
    fi
  done <<<"$updates"
  echo "$OFFSET" >"$OFFSET_FILE"
else
  echo "Error occurred while getting updates"
fi
