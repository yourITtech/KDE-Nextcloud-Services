#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh"

function get_share_form {

  # Create a single form for all share options
  form_output=$(zenity --forms --title="Create Public Nextcloud Share" \
    --text="Enter share options:" \
    --add-entry="Share Label (optional)" \
    --add-entry="Note to Recipient (optional)" \
    --add-password="Password (optional, min 10 chars)" \
    --add-combo="Allow Edit Permission" --combo-values="No|Yes" \
    --add-entry="Expiration Date (YYYY-MM-DD, default: $default_date)" \
    --separator="|" --width=565)

  # Check if the user clicked Cancel
  if [ $? -ne 0 ]; then
      zenity --error --text="Share creation cancelled."
      exit 1
  fi

  # Parse form output
  IFS='|' read -r share_label share_note share_password edit_permission expire_date <<< "$form_output"

  # Handle empty fields
  [ -z "$share_label" ] && share_label=""
  [ -z "$share_note" ] && share_note=""
  [ -z "$share_password" ] && share_password=""
  [ -z "$expire_date" ] && expire_date="$default_date"

  # Validate expiration date
  if ! date -d "$expire_date" >/dev/null 2>&1; then
      zenity --error --text="Invalid date format. Please use YYYY-MM-DD. Exiting."
      exit 1
  fi
  # Ensure date is in YYYY-MM-DD format
  expire_date=$(date -d "$expire_date" +%Y-%m-%d)

  # Set permissions based on edit_permission
  permissions=1  # Read by default
  if [ "$edit_permission" = "Yes" ]; then
      permissions=$((1 + 2))  # Read + Update = 3
  fi
}
get_share_form

function get_url {

  if [ $? -ne 0 ]; then
      zenity --error --text="Failed to fetch request token. Check network or URL."
      exit 1
  fi
  # Debug: Log requesttoken
  #echo "requesttoken=$token" >> /tmp/share_debug.log

  # Loop to handle password retries
  while true; do
    # Build the curl command with all parameters
    curl_data="path=$relative_path&shareType=3&expireDate=$expire_date"
    if [ -n "$share_password" ]; then
        curl_data="$curl_data&password=$share_password"
    fi
    if [ -n "$share_label" ]; then
        curl_data="$curl_data&label=$share_label"
    fi
    if [ -n "$share_note" ]; then
        curl_data="$curl_data&note=$share_note"
    fi
    curl_data="$curl_data&permissions=$permissions"

    # Debug: Log curl_data
    #echo "curl_data=$curl_data" >> /tmp/share_debug.log

    # Save curl output to a temporary file
    temp_file=$(mktemp)
    http_code=$(curl -s -X POST -u "$user_name:$pass_key" -H "OCS-APIRequest: true" -H "requesttoken: $token" --http1.1 -w "%{http_code}" -o "$temp_file" "https://$nc_url/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json" -d "$curl_data" 2>&1)

    # Check if curl command was successful
    if [ $? -ne 0 ]; then
        zenity --error --text="Curl command failed. Check the output in $temp_file"
        exit 1
    fi

    # Check HTTP status code
    #if [ "$http_code" -ne 200 ]; then
    #    cat "$temp_file" | zenity --text-info --title="Debug: Curl Output (HTTP $http_code)" --width=600 --height=400
    #    zenity --error --text="API request failed with HTTP status $http_code. Raw output saved in $temp_file"
    #    exit 1
    #fi

    # Check if response is valid JSON
    #jq . "$temp_file" >/dev/null 2>&1
    #if [ $? -ne 0 ]; then
    #    zenity --error --text="Invalid JSON response. Raw output saved in $temp_file"
    #    exit 1
    #fi

    # Check API response status
    api_status=$(jq -r '.ocs.meta.status' "$temp_file" 2>/dev/null)
    api_message=$(jq -r '.ocs.meta.message' "$temp_file" 2>/dev/null)

    if [ "$api_status" = "failure" ]; then
        # Check if the error is related to the password
        if [[ "$api_message" == *"compromised"* ]]; then
            zenity --error --text="Password rejected: $api_message\nPlease enter a stronger password (at least 10 characters, not common or compromised)."
            # Prompt for a new password
            share_password=$(zenity --entry --title="Set Share Password" --text="Enter a new password for the share link:\n- At least 10 characters\n- Not a common or compromised password" --hide-text)
            if [ $? -ne 0 ] || [ -z "$share_password" ]; then
                zenity --info --text="No password set. Proceeding without a password."
                share_password=""
            fi
            rm "$temp_file"
            continue
        else
            # Other API error
            cat "$temp_file" | zenity --text-info --title="Debug: Curl Output" --width=600 --height=400
            zenity --error --text="API error: $api_message\nRaw output saved in $temp_file"
            exit 1
        fi
    else
        # API call succeeded, extract the share URL
        share_url=$(jq -r '.ocs.data.url' "$temp_file" 2>/dev/null)
        #api_permissions=$(jq -r '.ocs.data.permissions' "$temp_file" 2>/dev/null)
        if [ $? -ne 0 ]; then
            cat "$temp_file" | zenity --text-info --title="Debug: Curl Output" --width=600 --height=400
            zenity --error --text="JQ error: $share_url\nRaw output saved in $temp_file"
            exit 1
        fi
        # Debug: Log share_url and api_permissions
        #echo "share_url=$share_url" >> /tmp/share_debug.log
        #echo "api_permissions=$api_permissions" >> /tmp/share_debug.log

        # Log the URL and Expiration Date in a hidden file in the Nextcloud home directory
        echo -e "$expire_date,$relative_path,$share_url" >> "$sync_folder/.kdencservicemenu"
        # Copy the URL to clipboard and notify user
        dbus-send --dest=org.kde.klipper --type=method_call /klipper org.kde.klipper.klipper.setClipboardContents string:"$share_url"
        kdialog --msgbox "Nextcloud share URL is now in your clipboard"
        rm "$temp_file"
        break
    fi
  done
}

if [[ "$local_path" == "$sync_folder"* ]]; then
  get_url
else
  # Notify user or silently exit
  kdialog --sorry "This action is only available in $sync_folder"
  exit 1
fi
