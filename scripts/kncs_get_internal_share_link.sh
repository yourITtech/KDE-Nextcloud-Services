#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh"

# Function to fetch the internal share link via OCS API
get_internal_link() {
    # Temporary file for API response
    temp_file=$(mktemp)

    # OCS API GET request to fetch the direct link
    http_code=$(curl -s -X GET -u "$user_name:$pass_key" -H "OCS-APIRequest: true" --http1.1 -w "%{http_code}" -o "$temp_file" \
        "https://$nc_url/ocs/v2.php/apps/files_sharing/api/v1/shares?path=$relative_path&format=json" 2>&1)

    # Check curl success
    if [ $? -ne 0 ] || [ "$http_code" -ne 200 ]; then
        zenity --error --text="Failed to fetch internal link. HTTP status: $http_code. Check credentials, path, or network.\nRaw output saved in $temp_file."
        rm "$temp_file"
        exit 1
    fi

    # Check API response
    api_status=$(jq -r '.ocs.meta.status' "$temp_file" 2>/dev/null)
    api_message=$(jq -r '.ocs.meta.message' "$temp_file" 2>/dev/null)

    if [ "$api_status" = "failure" ]; then
        zenity --error --text="API error: $api_message\nRaw output saved in $temp_file."
        rm "$temp_file"
        exit 1
    fi

    # Extract the internal link
    file_id=$(jq -r '.ocs.data[0].item_source' "$temp_file" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$file_id" ]; then
        zenity --error --text="Failed to acquire internal share link.\nAn internal share link cannot be generated unless you have shared the file.\nEither share the file, or login to WebUI and confirm the share has been created." --width=500
        rm "$temp_file"
        exit 1
    fi

    # Copy the link to the clipboard
    internal_link="https://$nc_url/f/$file_id"
    dbus-send --dest=org.kde.klipper --type=method_call /klipper org.kde.klipper.klipper.setClipboardContents string:"$internal_link"

    # Notify the user
    kdialog --msgbox "Internal share link copied to clipboard\nBe aware, only users you have shared this file\folder with can use this link."

    rm "$temp_file"
}

# Main logic
if [[ "$local_path" == "$sync_folder"* ]]; then
    get_internal_link
else
    kdialog --sorry "This action is only available in $sync_folder"
    exit 1
fi
