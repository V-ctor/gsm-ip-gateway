#!/bin/bash

# Variables
SCRIPT_PATH="/root/.sdkman/candidates/kotlin/current/bin/kotlinc -script /opt/asterisk/check_endpoint_state.main.kts"
WORKING_DIR="/opt/asterisk"
LOG_FILE="/var/log/endpoints_states.log"
CRON_COMMAND="cd $WORKING_DIR && $SCRIPT_PATH >> $LOG_FILE 2>&1"
CRON_JOB="0 * * * * $CRON_COMMAND"

# Check if the command already exists in crontab
if crontab -l 2>/dev/null | grep -qF "$CRON_COMMAND"; then
    echo "Cron job already exists."
else
    # Add the command to crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added: $CRON_JOB"
fi
