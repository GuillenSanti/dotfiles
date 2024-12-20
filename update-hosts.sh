#!/bin/bash

# Determine the path to the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to your local hosts file (the one you have in your dotfiles)
LOCAL_HOSTS_PATH="$dotfiles_dir/hosts"  # Adjusts the path based on your dotfiles directory

# Path to the temporary file that we will download from GitHub
TEMP_HOSTS_PATH="/tmp/fakenews-gambling-hosts"

# Path to the final /etc/hosts file
ETC_HOSTS_PATH="/etc/hosts"

# URL of StevenBlack's alternate hosts list (fakenews-gambling)
URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"

echo "Downloading the fakenews-gambling hosts file from StevenBlack..."

# Download the fakenews-gambling hosts file
curl -sSL $URL -o $TEMP_HOSTS_PATH

# Check if the download was successful
if [ ! -f "$TEMP_HOSTS_PATH" ]; then
    echo "Error downloading the hosts file. Exiting."
    exit 1
fi

echo "Merging the local hosts file with the downloaded file..."

# Combine the local file with the downloaded file, appending at the end
sudo bash -c "cat $LOCAL_HOSTS_PATH $TEMP_HOSTS_PATH > $ETC_HOSTS_PATH"

# Check if the merge was successful
if [ $? -eq 0 ]; then
    echo "The /etc/hosts file has been successfully updated."
else
    echo "There was an error updating the /etc/hosts file."
    exit 1
fi

# Remove the temporary file
rm -f $TEMP_HOSTS_PATH

echo "Process completed."
