##  L o o t B o x 

This script automates the installation of various tools on Debian-based systems. It installs software using `APT`, falls back to `Snap` when needed, installs `.deb` files, and clones GitHub repositories. Additionally, it logs all actions, tracks successes and failures, and saves these logs in a directory created in the user's home folder.

### Features:

- **APT/Snap Installation**:
    - Installs a list of specified software using `APT` or `Snap` (as a fallback).
- **.deb File Installation**:
    - Downloads `.deb` files from specified URLs and installs them. If the installation fails, it attempts to fix dependencies and retry the installation.
- **GitHub Repository Cloning**:
    - Clones specified repositories into the `lootme` directory. Skips cloning if the repository already exists.
- **Logging**:
    - All actions (installations, failures, and repository clones) are logged with timestamps in the `log.txt` file, located in the `lootme` directory.
- **Success/Failure Summary**:
    - At the end of the process, a summary of successful and failed installations is displayed and logged.

### Prerequisites:

- The script is designed for **Debian-based** systems.
- Must be run with **root** privileges (`sudo`).
- Requires **`wget`** and **`git`** to be installed for some features.

