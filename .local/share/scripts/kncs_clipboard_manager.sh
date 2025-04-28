#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh",

# Validate current_date
if ! date -d "$current_date" >/dev/null 2>&1; then
    zenity --error --text="Invalid current_date: $current_date. Exiting."
    exit 1
fi

# Function to clean expired shares
clean_expired_shares() {
    # Check if the file exists
    if [ ! -f "$url_logger" ]; then
        zenity --error --text="Share file not found at $url_logger. Exiting."
        exit 1
    fi

    # Temporary file for rewriting
    TEMP_FILE=$(mktemp)

    # Preserve header (lines up to and including # ------------------------)
    awk '/^# ------------------------$/{print; exit} {print}' "$url_logger" > "$TEMP_FILE"

    # Read data lines (after # ------------------------), filter out expired shares
    DATA_STARTED=0
    while IFS= read -r line; do
        # Detect start of data section
        if [ "$DATA_STARTED" -eq 0 ]; then
            if [[ "$line" == "# ------------------------" ]]; then
                DATA_STARTED=1
            fi
            continue
        fi

        # Parse line as comma-separated expire_date,location,url
        IFS=',' read -r expire_date location url <<< "$line"

        # Skip empty or malformed lines
        if [ -z "$expire_date" ] || [ -z "$location" ] || [ -z "$url" ]; then
            continue
        fi

        # Validate date format
        if ! date -d "$expire_date" >/dev/null 2>&1; then
            # Skip invalid dates
            continue
        fi

        # Debug: Log date comparison (commented out)
        #echo "Comparing $expire_date ($(date -d "$expire_date" +%s)) vs $current_date ($(date -d "$current_date" +%s))" >> /tmp/share_debug.log

        # Compare expiration date to current date
        if [ "$(date -d "$expire_date" +%s)" -ge "$(date -d "$current_date" +%s)" ]; then
            # Keep non-expired share
            echo "$expire_date,$location,$url" >> "$TEMP_FILE"
        fi
    done < "$url_logger"

    # Check if any valid shares remain
    DATA_LINES=$(tail -n +$(($(awk '/^# ------------------------$/{print NR; exit}' "$TEMP_FILE") + 1)) "$TEMP_FILE" | wc -l)
    if [ "$DATA_LINES" -eq 0 ]; then
        zenity --info --text="No valid (non-expired) shares found in $url_logger."
        rm "$TEMP_FILE"
        exit 0
    fi

    # Replace original file
    mv "$TEMP_FILE" "$url_logger"
}

# Clean expired shares
clean_expired_shares

# Prepare zenity list arguments
zenity_args=("--list" "--title=Nextcloud Share Links" "--text=Double-click a share to copy its URL to the clipboard:" "--column=Expiration Date" "--column=Location" "--column=URL" "--print-column=3" "--width=800" "--height=400")

# Read the share file, starting after # ------------------------
DATA_STARTED=0
while IFS= read -r line; do
    # Detect start of data section
    if [ "$DATA_STARTED" -eq 0 ]; then
        if [[ "$line" == "# ------------------------" ]]; then
            DATA_STARTED=1
        fi
        continue
    fi

    # Parse line as comma-separated expire_date,location,url
    IFS=',' read -r expire_date location url <<< "$line"

    # Skip empty or malformed lines
    if [ -z "$expire_date" ] || [ -z "$location" ] || [ -z "$url" ]; then
        continue
    fi

    # Add valid share to zenity arguments
    zenity_args+=("$expire_date" "$location" "$url")
done < "$url_logger"

# Display the zenity list and capture the selected URL
selected_url=$(zenity "${zenity_args[@]}")

# Check if the user cancelled or didn't select anything
if [ $? -ne 0 ] || [ -z "$selected_url" ]; then
    zenity --info --text="No URL selected. Exiting."
    exit 0
fi

# Copy the selected URL to the clipboard
dbus-send --dest=org.kde.klipper --type=method_call /klipper org.kde.klipper.klipper.setClipboardContents string:"$selected_url"

# Notify the user
kdialog --msgbox "Share URL copied to clipboard:\n$selected_url"
