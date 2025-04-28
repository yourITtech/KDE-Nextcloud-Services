#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh"

# Function to fetch shareable Nextcloud users via Sharee API
get_users() {
    # Temporary file for API response
    temp_file=$(mktemp)

    # GET request to fetch shareable users
    http_code=$(curl -s -X GET -u "$user_name:$pass_key" -H "OCS-APIRequest: true" --http1.1 -w "%{http_code}" -o "$temp_file" "https://$nc_url/ocs/v1.php/apps/files_sharing/api/v1/sharees?format=json&search=&itemType=file" 2>&1)

    if [ $? -ne 0 ] || [ "$http_code" -ne 200 ]; then
        zenity --error --text="Failed to fetch user list. HTTP status: $http_code. Check credentials or network."
        rm "$temp_file"
        exit 1
    fi

    # Parse user IDs from users and exact.users
    users=$(jq -r '.ocs.data.users[].value.shareWith, .ocs.data.exact.users[].value.shareWith' "$temp_file" 2>/dev/null | sort -u)
    if [ $? -ne 0 ] || [ -z "$users" ]; then
        zenity --error --text="No shareable users found or invalid response. Raw output saved in $temp_file."
        rm "$temp_file"
        exit 1
    fi

    # Store users for checklist
    user_array=()
    while IFS= read -r user; do
        user_array+=("FALSE" "$user")
    done <<< "$users"
    rm "$temp_file"
}

# Function to create the preliminary user selection form
get_user_selection() {
    # Fetch user list
    get_users

    # Create checklist form for user selection
    selected_users=$(zenity --list --checklist --title="Select Users to Share With" \
        --text="Select one or more users to share with:" \
        --column="Select" --column="User" \
        "${user_array[@]}" --separator=";" --width=400 --height=400)

    # Check if the user clicked Cancel or selected no users
    if [ $? -ne 0 ] || [ -z "$selected_users" ]; then
        zenity --error --text="No users selected. Share creation cancelled."
        exit 1
    fi

    # Set share_with for main form
    share_with="$selected_users"
}

# Function to create the main share form
get_share_form() {
    # Create form with share options
    form_output=$(zenity --forms --title="Create Internal Nextcloud Share" \
        --text="Enter share options for selected users ($share_with):" \
        --add-entry="Note to Recipient (optional)" \
        --add-combo="Allow Edit Permission" --combo-values="No|Yes" \
        --add-combo="Allow Share Permissions" --combo-values="No|Yes" \
        --add-entry="Expiration Date (YYYY-MM-DD, optional)" \
        --separator="|" --width=565)

    # Check if the user clicked Cancel
    if [ $? -ne 0 ]; then
        zenity --error --text="Share creation cancelled."
        exit 1
    fi

    # Parse form output
    IFS='|' read -r share_note edit_permission share_permission expire_date <<< "$form_output"

    # Handle empty fields
    [ -z "$share_note" ] && share_note=""
    [ -z "$expire_date" ] && expire_date=""

    # Validate share_with (already checked in preliminary form)
    IFS=';' read -ra share_users <<< "$share_with"

    # Validate expiration date if provided
    if [ -n "$expire_date" ]; then
        if ! date -d "$expire_date" >/dev/null 2>&1; then
            zenity --error --text="Invalid date format. Please use YYYY-MM-DD or leave blank. Exiting."
            exit 1
        fi
        # Ensure date is in YYYY-MM-DD format
        expire_date=$(date -d "$expire_date" +%Y-%m-%d)
    fi

    # Set permissions based on edit_permission and share_permission
    permissions=1  # Read by default
    if [ "$edit_permission" = "Yes" ]; then
        permissions=$((permissions + 2 + 4 + 8))  # Add update, create, delete
    fi
    if [ "$share_permission" = "Yes" ]; then
        permissions=$((permissions + 16))  # Add share
    fi
}

# Function to create internal shares
create_shares() {
    shares_created=0

    # Loop through selected users
    for user in "${share_users[@]}"; do
        # Build curl data
        curl_data="path=$relative_path&shareType=0&shareWith=$user"
        if [ -n "$expire_date" ]; then
            curl_data="$curl_data&expireDate=$expire_date"
        fi
        if [ -n "$share_note" ]; then
            curl_data="$curl_data&note=$share_note"  # Corrected from ¬e
        fi
        curl_data="$curl_data&permissions=$permissions"

        # Temporary file for API response
        temp_file=$(mktemp)

        # POST request to create share
        http_code=$(curl -s -X POST -u "$user_name:$pass_key" -H "OCS-APIRequest: true" -H "Content-Type: application/x-www-form-urlencoded" --http1.1 -w "%{http_code}" -o "$temp_file" "https://$nc_url/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json" -d "$curl_data" 2>&1)

        # Check curl success
        if [ $? -ne 0 ]; then
            zenity --error --text="Curl command failed for user $user. Check the output in $temp_file."
            rm "$temp_file"
            continue
        fi

        # Check API response
        api_status=$(jq -r '.ocs.meta.status' "$temp_file" 2>/dev/null)
        api_message=$(jq -r '.ocs.meta.message' "$temp_file" 2>/dev/null)

        if [ "$api_status" = "failure" ]; then
            zenity --error --text="API error for user $user: $api_message\nRaw output saved in $temp_file."
            rm "$temp_file"
            continue
        fi

        shares_created=$((shares_created + 1))
        rm "$temp_file"
    done

    # Check if any shares were created
    if [ "$shares_created" -gt 0 ]; then
        kdialog --msgbox "Internal Nextcloud share(s) created successfully for $shares_created user(s)."
    else
        zenity --error --text="No shares were created successfully."
        exit 1
    fi
}

# Main logic
if [[ "$local_path" == "$sync_folder"* ]]; then
    get_user_selection
    get_share_form
    create_shares
else
    kdialog --sorry "This action is only available in $sync_folder"
    exit 1
fi
