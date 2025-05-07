# KDE-Nextcloud-Services

Kubuntu v24.10 has had issue integrating with Nextcloud using Dolphin. This project aims to add Nextcloud integration directly into the KDE windows manager using the NC API system in a very direct way using curl and bash scripts.

![image](https://github.com/user-attachments/assets/c1b2f5b5-1616-40b5-9ac5-9fcfcca333f1)

#### Dependencies

`KDE Plasma 6`, `curl`, `zenity`, `kwallet`, `busctl`

#### Installation

- Download release .zip
  
- Place all the `.sh` (Scripts), `.desktop & .desktop.disabled` (Service Menus), `.svg` (Icons) in their appropriate folders as specified below.

#### Locations
If these locations do not exist, create them.

- Scripts: `~/.local/share/scripts`

- Service Menus: `~/.local/share/kio/servicemenus`

- Icons: `~/.local/share/icons/hicolor/scalable/apps`

#### Uninstall

- Click Disconnect from Nextcloud in the service menu.

- Delete all files labeled `kncs_` in the above file locations.

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

#### Script Info

- `kncs_connect_nc.sh`
  
  - The script is designed to present users a Zenity form to have them input their Nextcloud URL, username, app password and Nextcloud sync locations. Once they hit OK, the script uses these variables to put these details into KWallet to be used in other script.
  
  - The script also creates a file named `.kdencservicemenu` in the Nextcloud Sync home directory. This file is used to document and later query shares, URL's and  expiration dates of shares created by this system.
  
  - This script also calls the `kncs_enable_disable.sh` script to rename all `kncs_*.desktop` files to `kncs_*.desktop.disabled` and vice versa. This enables and disables the service menus the KDE queries.

- `kncs_enable_disable.sh`
  
  - This script was designed to be sourced into other scripts. It is a single function scripts and when called, identifies all files with the string `kncs` in the folder location `~/local/share/kio/servicemenus` and renames all identified files from `.desktop` to `.desktop.disabled` and visa versa. This disables and enables services menus when "connection and disconnecting" to Nextcloud.

- `kncs_variables.sh`
  
  - This script was designed to be sourced into other scripts. This houses all the constant variables needed for this app to operate.

- `kncs_clipboard_manager.sh`
  
  - This script was designed to be present users with a Zenity form displaying all shares created by this app. When the script is called, it looks into the `.kdencservicemenu` log file, finds expired shares that have been logged and removes them, then displays a 3 column Zenity form with expiration date, file/folder shared and the URL that was generated. If you double click the row it will put the URL back into your clipboard.

- `kncs_generate_preview_url.sh`
  
  - This script was designed to create a public share link for images so you can share them with users using the share link appended with `/preview`. 
  
  - The script gets your Nextcloud path when you use the right click menu. 
  
  - Then it queries your KWallet info with the path to send a POST to the file in your Nextcloud to set a read only public share, with a 7 day expire, then places the share link into your clipboard.
  
  - The expiration date, the file and URL is logged in the `.kdencservicemenu` file.

- `kncs_generate_share_url.sh`
  
  - This script was designed to create a public share link for files and folders so you can share them with external users using the share link. 
  
  - The script gets your Nextcloud path when you use the right click menu. 
  
  - A Zenity form is presented to the user asking the user to define an expiration date.
  
  - Another Zenity form is presented to the user asking to define Share Label, Note to Recipient, Password, and Edit Permissions. 
  
  - Then it queries your KWallet info with all the details above to send a POST to the file or folder in your Nextcloud, with the settings defined, then places the share link into your clipboard.
  
  - The expiration date, the file/folder and URL is logged in the `.kdencservicemenu` file.

- `kncs_generate_internal_share.sh`
  
  - This script was designed to create a internal share link for files and folders so you can share them with internal Nextcloud users using the share link.
  
  - The script gets your Nextcloud path when you use the right click menu.
  
  - A GET request is sent to the Nextcloud server to get a list of available users your users can share with. 
  
  - Then a Zenity form is presented asking the user to define what Nextcloud users to share with.
  
  - Another Zenity form is presented to the user asking the user to define an expiration date.
  
  - Another Zenity form is presented to the user asking to define Note to Recipient, Edit Permissions, and Edit Permissions.
  
  - Then it queries your KWallet info with all the details above to send a POST to the file or folder in your Nextcloud with the settings defined.
  
  - Based on the internal users notification settings, if enabled will receive and email and/or push notification the share was created.

- `kncs_get_internal_share_link.sh`
  
  - This script was designed to acquire the share link for an internal share. There is currently a limitation in the NC API where you cant explicitly access this URL through a GET call. To get this link the script has to manufacture it.
  
  - A GET request is sent to get the file ID. If the `item_source` field is not returned, then the file/folder does not have a internal share configured.
  
  - If the `item_source` is returned, then the script manufactures the internal link and Nextcloud url from the KWallet.
    
    - `https://<nc_url>/f/<item_source>`

- `kncs_disconnect_nc.sh`
  
  - This script was designed to "Disconnect" your Dolphin from the Nextcloud Server.
  
  - A prompt is presented asking users to confirm they want to disconnect from Nextcloud. After pressing yes, the script delete the `.kdencservicemenu`, deletes the KWallet entry created on connection and then calls the `kncs_enable_disable.sh` script is disabled the service menus.
  
  - The `Connect to Nextcloud` menu is re-enabled so that you can re-connect at a later time.
