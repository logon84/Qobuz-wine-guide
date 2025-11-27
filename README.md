# Qobuz-wine-guide
A guide to make Qobuz run bitperfect under linux

Guide to install Qobuz app on linux, trying to achieve the best possible latency/quality playback.

#INSTALLING WINE-STAGING:
```
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
sudo apt update
sudo apt install wine-staging wine-staging-amd64 wine-staging-i386 inotify-tools
WINEPREFIX=~/.wine-staging /opt/wine-staging/bin/winecfg
```
At this point, set:

-Windows 7 as OS  
-Enable VAAPI as backend

-Idk if it is important, but I downloaded this file https://dll.website/download/msvproc_dll_417e414c57cd55fdee5f0bdcf331c967.zip and copied the dll to ~/.wine-staging/drive_c/windows/syswow64

#CHANGE WINE AUDIO TO ALSA:
```
WINEPREFIX=~/.wine-staging WINE=/opt/wine-staging/bin/wine winetricks
```
-->default wine prefix->change settings->sound=alsa

#INSTALL QOBUZ:  
First, run installer prequisites.sh

Then:
```
wget https://desktop.qobuz.com/releases/win32/x64/windows7_8_10/8.1.0-b019/Qobuz_Installer.exe
WINEPREFIX=~/.wine-staging /opt/wine-staging/bin/wine Qobuz_Installer.exe
```
Now Qobuz should open asking for login.
After logging in, close Qobuz. Edit the Qobuz launcher that the installer created on your Desktop and change the text before the C:\users\....path to:
```
env WINEPREFIX="~/.wine-staging" /opt/wine-staging/bin/wine
```
#PIPEWIRE CONFIG:  
Now check if you have a file named pipewire.conf in ~/.config/pipewire/. If you don't, copy the file from /usr/share/pipewire/pipewire.conf to that folder.
Open the file and edit the line containing: "#default.clock.allowed-rates"

to

"default.clock.allowed-rates = [ 44100 48000 96000 176400 192000]"

(check also these files: ~/.config/pipewire/pipewire.conf, ~/.config/pipewire/pipewire-pulse.conf and ~/.config/wireplumber/main.lua.d/50-alsa-config

Restart the pipewire daemon with: 
```
systemctl --user restart wireplumber pipewire pipewire-pulse
```
Open pavucontrol and change playback device to the "pro" profile.

Copy steam-wire.lua to folder "$HOME/.config/wireplumber/scripts/

#ENJOY  
From now on, open Qobuz using the qobuz_launcher script (hold shift key or run script with -exclusive flag to use exclusive mode). If you have problems choosing output device go to playback settings and turn off "exclusive mode".
Now you should be able to use Qobuz app from Linux. Be sure to select your audio device as output and play some High-res music.
Select Max playing quality clicking on the quality section, between volume control and pulseaudio Label.
To avoid problems you should set 2 channel audio (stereo) in 50-alsa-config.lua and in winecfg audio tab (env WINEPREFIX="$HOME/.wine-staging" /opt/wine-staging/bin/winecfg).

[![Donate](https://www.paypalobjects.com/es_ES/ES/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ER2LTNM5LZDTY)  
BTC address: 12cQuFn7yMSfDB1uKPGKLMQ7XSj1XF2sVA

