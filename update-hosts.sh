#!/bin/bash

# Ask for confirmation before proceeding
echo "This script will update your /etc/hosts file with additional entries."
echo "Do you want to continue? (yes/no)"
read -r user_confirmation

if [[ ! "$user_confirmation" =~ ^(yes|y)$ ]]; then
    echo "Operation cancelled by the user. Exiting..."
    exit 0
fi

# Determine the path to the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to your local hosts file (the one you have in your dotfiles)
LOCAL_HOSTS_PATH="$dotfiles_dir/hosts"  # Adjust the path based on your dotfiles directory

# Path to your .hosts.local file
LOCAL_HOSTS_LOCAL_PATH="$dotfiles_dir/hosts.local"

# Path to the temporary file that we will download from GitHub
TEMP_HOSTS_PATH="/tmp/fakenews-gambling-hosts"

# Path to the final /etc/hosts file
ETC_HOSTS_PATH="/etc/hosts"

# URL of StevenBlack's alternate hosts list (fakenews-gambling)
URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"

echo "Downloading the fakenews-gambling hosts file from StevenBlack..."

# Download the fakenews-gambling hosts file
curl -sSL "$URL" -o "$TEMP_HOSTS_PATH"

# Check if the download was successful
if [ ! -f "$TEMP_HOSTS_PATH" ]; then
    echo "Error downloading the hosts file. Exiting."
    exit 1
fi

# Create a temporary combined file to avoid partial updates
COMBINED_HOSTS_PATH="/tmp/combined-hosts"

echo "Merging the local hosts file, hosts.local, and the downloaded file..."

# Add a comment and merge the local hosts file
if [ -f "$LOCAL_HOSTS_PATH" ]; then
    {
        echo "# Hosts from $LOCAL_HOSTS_PATH"
        cat "$LOCAL_HOSTS_PATH"
        echo ""
    } > "$COMBINED_HOSTS_PATH"
else
    echo "Warning: Local hosts file ($LOCAL_HOSTS_PATH) not found. Skipping."
fi

# Add a comment and merge the hosts.local file
if [ -f "$LOCAL_HOSTS_LOCAL_PATH" ]; then
    {
        echo ""
        echo "# Hosts from $LOCAL_HOSTS_LOCAL_PATH"
        cat "$LOCAL_HOSTS_LOCAL_PATH"
        echo ""
    } >> "$COMBINED_HOSTS_PATH"
else
    echo "Warning: hosts.local file ($LOCAL_HOSTS_LOCAL_PATH) not found. Skipping."
fi

# Add a comment and merge the downloaded hosts file
{
    echo "# Hosts from StevenBlack's fakenews-gambling list"
    cat "$TEMP_HOSTS_PATH"
    echo ""
} >> "$COMBINED_HOSTS_PATH"

# Update the /etc/hosts file with the combined content
sudo mv "$COMBINED_HOSTS_PATH" "$ETC_HOSTS_PATH"

# Check if the update was successful
if [ $? -eq 0 ]; then
    echo "The /etc/hosts file has been successfully updated."
else
    echo "There was an error updating the /etc/hosts file."
    exit 1
fi

# Remove the temporary downloaded file
rm -f "$TEMP_HOSTS_PATH"

echo "Process completed."
