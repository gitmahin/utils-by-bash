# !/bin/bash

# Exit immediately if exits with a non-zero status.
set -e

current_path=$(pwd)

START_SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# create symbolic link
sudo ln -s "$START_SCRIPT_DIR/run.sh" /usr/bin/cpprun