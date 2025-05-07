#!/bin/bash
source "$HOME/.local/share/scripts/kncs_variables.sh"

function get_url {
  share_url=$(curl -s -X POST -u $user_name:$pass_key -H "OCS-APIRequest: true" -H "requesttoken: $token" --http1.1 "https://$nc_url/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json" \
  -d "path=$relative_path&shareType=3&expireDate=$default_date" | jq -r '.ocs.data.url')
  preview_url="${share_url}/preview"
  echo -e "$default_date,$relative_path,$preview_url" >> "$sync_folder/.kdencservicemenu"
  dbus-send --dest=org.kde.klipper --type=method_call /klipper org.kde.klipper.klipper.setClipboardContents string:"$preview_url"
  kdialog --msgbox "Nextcloud share URL is now in your clipboard"
}

if [[ "$local_path" == "$sync_folder"* ]]; then
  get_url
else
  # Optionally notify user or silently exit
  kdialog --sorry "This action is only available in $sync_folder"
  exit 1
fi
