#!/bin/bash
function enable_disable {
  # Define the target directory
  local dir="$HOME/.local/share/kio/servicemenus"

  # Check if directory exists
  if [[ ! -d "$dir" ]]; then
      echo "Error: Directory $dir does not exist"
      return 1
  fi

  # Change to the target directory
  cd "$dir" || return 1

  # Find files containing 'kncs' in their name
  for file in kncs*; do
      # Check if file exists to avoid errors
      if [[ -f "$file" ]]; then
          # Operation 1: Rename .desktop.disabled to .desktop
          if [[ "$file" == *.desktop.disabled ]]; then
              new_name="${file%.desktop.disabled}.desktop"
              mv "$file" "$new_name"
              echo "Renamed: $file -> $new_name"
          # Operation 2: Rename .desktop to .desktop.disabled
          elif [[ "$file" == *.desktop ]]; then
              new_name="${file%.desktop}.desktop.disabled"
              mv "$file" "$new_name"
              echo "Renamed: $file -> $new_name"
          fi
      fi
  done
}
