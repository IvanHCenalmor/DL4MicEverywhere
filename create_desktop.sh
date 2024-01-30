#!/bin/bash

# Get the base directory of DL4MicEveywhere repository
BASEDIR=$(dirname "$(readlink -f "$0")")

# Create the double-click launching desktop file
echo "[Desktop Entry]
Type=Application
Name=DL4MicEverywhere
Exec=$BASEDIR/launch.sh
Terminal=true
Icon=$BASEDIR/docs/logo/dl4miceverywhere-logo-small.png" > ~/Desktop/DL4MicEverywhere.desktop

# Allow execution
chmod a+x ~/Desktop/DL4MicEverywhere.desktop
