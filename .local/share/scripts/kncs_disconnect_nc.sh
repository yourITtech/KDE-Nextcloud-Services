#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh"
source "$script_dir/kncs_enable_disable.sh"

# Display confirmation prompt
zenity --question --title="Disconnect from Nextcloud" \
    --text="Do you really want to disconnect from Nextcloud?" \
    --ok-label="Yes" --cancel-label="No" \
    --width=400 --height=200 2>/dev/null

# Check user response
if [ $? -eq 0 ]; then
    echo "User chose Yes: Disconnecting from Nextcloud."
else
    echo "User chose No: Aborting disconnection."
    exit 1
fi

# Delete servicemenus URL Log
rm $sync_folder/.kdencservicemenu

# Get kwallet app password Entry
OUTPUT=$(kwallet-query -l -f Nextcloud kdewallet | grep MENU)

# Delete user kwallet entry
busctl --user call org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet removeEntry isss $kwallet_id Nextcloud $OUTPUT ""

# Switch servicemenus
enable_disable
