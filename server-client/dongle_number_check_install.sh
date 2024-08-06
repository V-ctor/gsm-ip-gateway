#!/bin/ash

# Variables
SCRIPT_NAME="dongle_number.check.sh"
SCRIPT_PATH="/root/scripts/$SCRIPT_NAME"
CRON_JOB="0 * * * * $SCRIPT_PATH"

# Ensure /root/scripts/ directory exists
if [ ! -d /root/scripts ]; then
    mkdir -p /root/scripts
    echo "Directory /root/scripts created."
else
    echo "Directory /root/scripts already exists."
fi

# Copy the script to /root/scripts/
cp $SCRIPT_NAME $SCRIPT_PATH
echo "Copied $SCRIPT_NAME to $SCRIPT_PATH"

# Make sure the script is executable
chmod +x "$SCRIPT_PATH"
echo "Made $SCRIPT_PATH executable."

# Function to check if a cron job already exists
cron_job_exists() {
    crontab -l | grep -F "$SCRIPT_PATH" > /dev/null 2>&1
}

# Function to add the cron job if it doesn't exist
add_cron_job() {
    if ! cron_job_exists; then
        (crontab -l; echo "$CRON_JOB") | crontab -
        echo "Cron job added: $CRON_JOB"
    else
        echo "Cron job already exists."
    fi
}

# Add the cron job
add_cron_job