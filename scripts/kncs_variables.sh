#!/bin/bash
# Identify the directory in which the user initiated the scripts
local_path="$1"
# Get the servicemenu nextcloud app password, username and nextcloud URL from Kwallet to use in the API calls
OUTPUT=$(kwallet-query -l -f Nextcloud kdewallet | grep MENU)
# Extract username from kwallet output
user_name=$(echo "$OUTPUT" | cut -d':' -f2)
# Extract URL from kwallet output
nc_url=$(echo "$OUTPUT" | cut -d':' -f3)
# Extract sync location from kwallet output
sync_folder=$(echo "$OUTPUT" | cut -d':' -f4)
# Extract password from kwallet-query output
pass_key=$(kwallet-query -r $OUTPUT -f Nextcloud kdewallet)
# Where all the scripts live
script_dir="$HOME/.local/share/scripts"
# Where all the KDE menus live
menu_dir="$HOME/.local/share/kio/servicemenus"
# Get kwallet kdewallet ID
kwallet_id=$(busctl --user call org.kde.kwalletd5 /modules/kwalletd5 org.kde.KWallet open sxs "kdewallet" 0 "" | awk '{print $2}')
# Calculate default expiration date (7 days from now)
default_date=$(date -d '+7 days' +%Y-%m-%d)
# Current date in YYYY-MM-DD
current_date=$(date +%Y-%m-%d)
# Getting the Nextcloud folder structure to be able to use it in the API call
relative_path="${local_path#$sync_folder}"
# Get API request token
token=$(curl -s -I --http1.1 https://$nc_url/index.php | grep -i requesttoken | cut -d' ' -f2 | tr -d '\r')
# Share URL Log file
url_logger="$sync_folder/.kdencservicemenu"
