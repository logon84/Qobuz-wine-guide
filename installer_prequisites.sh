#!/bin/bash

#Qobuz qobuzapp protocol installer

#Edit this 2 vars if needed
wine_prefix="$HOME/.wine-staging"
wine_binary="/opt/wine-staging/bin/wine"

#Get wine username
wine_username=$(env $(eval "WINEPREFIX=$wine_prefix") $wine_binary cmd /c set | grep "^USERNAME=" | awk -F '=' '{print ($2)}'  | tr -d '\r')

#create launcher
echo "[Desktop Entry]" > $HOME/.local/share/applications/wine-qobuz.desktop
echo "Type=Application" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "Name=Qobuz" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "MimeType=x-scheme-handler/qobuzapp;" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "Exec=env WINEPREFIX="$wine_prefix" $wine_binary C:\\\\\\\\users\\\\\\\\$wine_username\\\\\\\\AppData\\\\\\\\Local\\\\\\\\Qobuz\\\\\\\\Qobuz.exe  %u" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "Terminal=false" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "StartupNotify=true" >> $HOME/.local/share/applications/wine-qobuz.desktop
echo "Icon=5D72_Qobuz.0" >> $HOME/.local/share/applications/wine-qobuz.desktop
chmod +x $HOME/.local/share/applications/wine-qobuz.desktop

#delete default wine launcher
rm -rf $HOME/.local/share/applications/wine/Programs/Qobuz

#register protocol with launcher
xdg-mime default $HOME/.local/share/applications/wine-qobuz.desktop x-scheme-handler/qobuzapp

#final comments
echo -e "\nYou can now see which launcher handles qobuzapp protocol running command: xdg-mime query default x-scheme-handler/qobuzapp"
echo ""
echo -e "\nYou can test the protocol launcher by running: xdg-open qobuzapp://thisisatest"
