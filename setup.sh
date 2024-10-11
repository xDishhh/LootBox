#!/bin/bash

# check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# check for Debian-based system
if [ ! -f "/etc/debian_version" ]; then
    echo "This script is for Debian-based systems only"
    exit 1
fi

# get the actual user who ran the script with sudo
REAL_USER=$(logname)
USER_HOME=$(eval echo ~$REAL_USER)
LOOT_DIR="$USER_HOME/lootme"

# create lootme directory
mkdir -p "$LOOT_DIR"
chown $REAL_USER:$REAL_USER "$LOOT_DIR"

# update system
echo "Updating system..."
apt-get update && apt-get upgrade -y

# function to install apt packages
install_apt() {
    for package in "$@"; do
        echo "Installing $package..."
        apt-get install -y "$package"
    done
}

# function to download .deb files
download_deb() {
    local url=$1
    local filename=$(basename "$url")
    echo "Downloading $filename..."
    wget -q --show-progress -P "$LOOT_DIR" "$url"
    # Set correct ownership
    chown $REAL_USER:$REAL_USER "$LOOT_DIR/$filename"
    echo "$filename downloaded to $LOOT_DIR"
}

# function to install .deb files
install_deb() {
    for deb in "$@"; do
        if [[ $deb == http* ]]; then
            # If it's a URL, download it first
            download_deb "$deb"
            deb="$LOOT_DIR/$(basename "$deb")"
        elif [[ $deb != $LOOT_DIR/* ]]; then
            # If it's a local file not in LOOT_DIR, copy it there
            cp "$deb" "$LOOT_DIR/"
            deb="$LOOT_DIR/$(basename "$deb")"
            chown $REAL_USER:$REAL_USER "$deb"
        fi
        echo "Installing $(basename "$deb")..."
        dpkg -i "$deb" || {
            echo "Fixing dependencies..."
            apt-get install -f -y
            dpkg -i "$deb"
        }
    done
}

# function to clone GitHub repositories
clone_github_repo() {
    for repo in "$@"; do
        repo_name=$(basename "$repo" .git)
        repo_dir="$LOOT_DIR/$repo_name"
        if [ ! -d "$repo_dir" ]; then
            echo "Cloning $repo into $repo_dir..."
            git clone "$repo" "$repo_dir"
            chown -R $REAL_USER:$REAL_USER "$repo_dir"
            echo "Repository $repo_name cloned to $repo_dir"
        else
            echo "Repository $repo_name already exists in $LOOT_DIR. Skipping..."
        fi
    done
}

# list of apt packages to install
APT_PACKAGES=("git" "curl" "vim")

# list of .deb files to install (local files and URLs)
DEB_FILES=(
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    "/path/to/local/file.deb"
)

# list of GitHub repositories to clone
GITHUB_REPOS=(
    "https://github.com/ffuf/ffuf.git"
    "https://github.com/danielmiessler/SecLists.git"
)

# install apt packages
install_apt "${APT_PACKAGES[@]}"

# install .deb files
install_deb "${DEB_FILES[@]}"

# clone GitHub repositories
clone_github_repo "${GITHUB_REPOS[@]}"

echo "Installation complete! All files and repositories are stored in $LOOT_DIR"
ls -la "$LOOT_DIR"
