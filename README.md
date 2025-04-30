# KDE-Nextcloud

Nextcloud has lacked service menu integration. This project aims to add Nextcloud integration directly into the KDE windows manager using the NC API system, so that you can be more productive while working. No more needing to keep the WebUI open to manage file access for internal and external users.

#### Features

This is the current list of features this service menu will add to your dolphin file manager in KDE. See "Script Info" for more detailed information on what each script does.

- Connect to Nextcloud
  
  - This option allows you to set your Nextcloud instance URL, your username and password and the location in which your Nextcloud files are being synced to by the Nextcloud Sync Client using KWallet. This allows this app to function without having any sensitive information being input into script variables.

- Generate Preview URL
  
  - This option allows you to generate a public share link with a 7 days expiration date on image files only, then puts a URL into your clipboard so you can link images to other people to view in their web browser.

- Generate Share URL
  
  - This option allows you to generate a public share link, with a customizable expiration date, then puts a URL into your clipboard so people download remote files from their web browser.

- Share With User
  
  - This option allow you to generate an internal share with other users that your user has access to share with. This will trigger the Nextcloud notification API to send email and push notifications to said user that you have shared something with them.

- Internal Share Link
  
  - This option allows you to grab the internal share link from an existing internal share. It will place this URL into your clipboard so you can easily link it to other internal users to quickly find the share.

- Clipboard Manager
  
  - This option will allow you to view shares that were created by this system and view their expiration dates and if needed, place the share URL back into your clipboard.

- Disconnect from Nextcloud
  
  - This option will remove the KWallet entries, disabled all service menus, clean up logs, and restore the "Connect to Nextcloud" service menu.

#### Locations

- Scripts: `~/.local/share/scripts`

- Service Menus: `~/.local/share/kio/servicemenus`

- Icons: `~/.local/share/icons`

#### Script Info

- `kncs_connect_nc.sh`
  
  - The script is designed to present users a Zenity form to have them input their Nextcloud URL, username, app password and Nextcloud sync locations. Once they hit OK, the script uses these variables to put these details into KWallet to be used in other script.
  
  - The script also creates a file named `.kdencservicemenu` in the Nextcloud Sync home directory. This file is used to document and later query shares, URL's and  expiration dates of shares created by this system.
  
  - This script also calls the `kncs_enable_disable.sh` script to rename all `kncs_*.desktop` files to `kncs_*.desktop.disabled` and vice versa. This enables and disables the service menus the KDE queries.

- `kncs_enable_disable.sh`
  
  - This script was designed to be sourced into other scripts. It is a single function scripts and when called, identifies all files with the string `kncs` in the folder location `~/local/share/kio/servicemenus` and renames all identified files from `.desktop` to `.desktop.disabled` and visa versa. This disables and enables services menus when "connection and disconnecting" to Nextcloud.

- `kncs_variables.sh`
  
  -  This script was designed to be sourced into other scripts. This houses all the constant variables needed for this app to operate.

- `kncs_clipboard_manager.sh`
  
  - This script was designed to be present users with a Zenity form displaying all shares created by this app. When the script is called, it looks into the `.kdencservicemenu` log file, finds expired shares that have been logged and removes them, then displays a 3 column Zenity form with expiration date, file/folder shared and the URL that was generated. If you double click the row it will put the URL back into your clipboard.

- `kncs_generate_preview_url.sh`
  
  - This script was designed to

- `kncs_generate_share_url.sh`
  
  - This script was designed to

- `kncs_generate_internal_share.sh`
  
  - This script was designed to

- `kncs_get_internal_share_link.sh`
  
  - This script was designed to

- `kncs_disconnect_nc.sh`
  
  - This script was designed to
