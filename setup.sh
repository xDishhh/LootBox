#!/bin/bash

# define the directory for logs and cloned repositories
USER_HOME=$(eval echo ~$SUDO_USER)
LOOT_DIR="$USER_HOME/lootme"
LOG_FILE="$LOOT_DIR/log.txt"

# check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# ensure system is Debian-based
if [ ! -f "/etc/debian_version" ]; then
    echo "This script is for Debian-based systems only"
    exit 1
fi

# create the loot directory and log file
mkdir -p "$LOOT_DIR"
touch "$LOG_FILE"
chown $SUDO_USER:$SUDO_USER "$LOOT_DIR" "$LOG_FILE"

# logging function
log_action() {
    local status="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$status] - $message" | tee -a "$LOG_FILE"
}

# function to install apt packages or fallback to snap
install_package() {
    local package=$1

    if apt-cache show "$package" &>/dev/null; then
        log_action "INFO" "Installing $package via APT."
        if apt-get install -y "$package"; then
            log_action "SUCCESS" "$package installed via APT."
            SUCCESS_TOOLS+=("$package")
        else
            log_action "ERROR" "Failed to install $package via APT."
            FAILED_TOOLS+=("$package")
        fi
    else
        log_action "INFO" "$package not available via APT. Attempting Snap installation."
        if snap search "$package" | grep -q "^$package "; then
            if snap install "$package"; then
                log_action "SUCCESS" "$package installed via Snap."
                SUCCESS_TOOLS+=("$package")
            else
                log_action "ERROR" "Failed to install $package via Snap."
                FAILED_TOOLS+=("$package")
            fi
        else
            log_action "ERROR" "$package not available via APT or Snap."
            FAILED_TOOLS+=("$package")
        fi
    fi
}

# function to download and install .deb files
install_deb() {
    local deb_url=$1
    local filename=$(basename "$deb_url")
    local deb_path="$LOOT_DIR/$filename"

    log_action "INFO" "Downloading $filename..."
    if wget -q --show-progress -P "$LOOT_DIR" "$deb_url"; then
        log_action "SUCCESS" "$filename downloaded to $LOOT_DIR."
    else
        log_action "ERROR" "Failed to download $filename."
        FAILED_TOOLS+=("$filename")
        return
    fi

    log_action "INFO" "Installing $filename..."
    if dpkg -i "$deb_path"; then
        log_action "SUCCESS" "$filename installed successfully."
        SUCCESS_TOOLS+=("$filename")
    else
        log_action "WARNING" "Failed to install $filename. Attempting to fix dependencies."
        apt-get install -f -y
        if dpkg -i "$deb_path"; then
            log_action "SUCCESS" "$filename installed successfully after fixing dependencies."
            SUCCESS_TOOLS+=("$filename")
        else
            log_action "ERROR" "Failed to install $filename even after fixing dependencies."
            FAILED_TOOLS+=("$filename")
        fi
    fi
}

# function to clone GitHub repositories
clone_repo() {
    local repo_url=$1
    local repo_name=$(basename "$repo_url" .git)
    local repo_dir="$LOOT_DIR/$repo_name"

    if [ -d "$repo_dir" ]; then
        log_action "INFO" "Repository $repo_name already exists. Skipping clone."
        SUCCESS_TOOLS+=("$repo_name (already exists)")
    else
        log_action "INFO" "Cloning $repo_url into $repo_dir..."
        if git clone "$repo_url" "$repo_dir"; then
            log_action "SUCCESS" "Repository $repo_name cloned successfully."
            SUCCESS_TOOLS+=("$repo_name")
        else
            log_action "ERROR" "Failed to clone $repo_name."
            FAILED_TOOLS+=("$repo_name")
        fi
    fi
}

# packages to install via apt or snap (if not available)
APT_PACKAGES=("curl" "flameshot" "git"  "gobuster" "nmap" "vim")

# GitHub repositories to clone
GITHUB_REPOS=(
    "git clone https://github.com/danielmiessler/SecLists.git"
    "git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git"

)

# List of .deb files to install (local files or URLs)
DEB_FILES=(
    "http://example.com/path/to/file.deb"
    
)

# initialize success and failure tracking arrays
SUCCESS_TOOLS=()
FAILED_TOOLS=()

# start logging
log_action "INFO" "Starting installation process."

# install apt/snap packages
for package in "${APT_PACKAGES[@]}"; do
    install_package "$package"
done

# install .deb files
for deb_url in "${DEB_FILES[@]}"; do
    install_deb "$deb_url"
done

# clone GitHub repositories
for repo in "${GITHUB_REPOS[@]}"; do
    clone_repo "$repo"
done

# display and log installation summary
echo
echo "Installation Summary:"
echo "---------------------"

if [ ${#SUCCESS_TOOLS[@]} -ne 0 ]; then
    echo "Successfully installed:"
    for tool in "${SUCCESS_TOOLS[@]}"; do
        echo "  - $tool"
    done
    log_action "INFO" "Successfully installed: ${SUCCESS_TOOLS[*]}"
else
    log_action "INFO" "No successful installations."
fi

if [ ${#FAILED_TOOLS[@]} -ne 0 ]; then
    echo "Failed to install:"
    for tool in "${FAILED_TOOLS[@]}"; do
        echo "  - $tool"
    done
    log_action "ERROR" "Failed to install: ${FAILED_TOOLS[*]}"
else
    log_action "INFO" "No failed installations."
fi

# final message
log_action "INFO" "Installation process complete. All logs saved in $LOG_FILE."
echo
echo "All tools and logs are stored in $LOOT_DIR."
ls -la "$LOOT_DIR"
